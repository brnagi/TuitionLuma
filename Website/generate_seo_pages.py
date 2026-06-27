#!/usr/bin/env python3
import html
import json
import os
import re
import statistics
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SITE_URL = "https://tuitionluma.pages.dev"
TODAY = date.today().isoformat()

SCHOOL_FIELDS = [
    "id",
    "school.name",
    "school.city",
    "school.state",
    "school.ownership",
    "latest.student.size",
    "latest.cost.avg_net_price.overall",
    "latest.earnings.10_yrs_after_entry.median",
    "latest.completion.completion_rate_4yr_150nt",
    "latest.aid.median_debt.completers.overall",
    "latest.admissions.admission_rate.overall",
    "latest.cost.attendance.academic_year",
    "latest.cost.tuition.in_state",
    "latest.cost.tuition.out_of_state",
]

PROGRAMS = [
    ("computer-science", "Computer Science", "technology", "software, data, security, and systems careers"),
    ("business-administration", "Business Administration", "business", "management, operations, finance, and entrepreneurship paths"),
    ("nursing", "Nursing", "healthcare", "patient care, clinical practice, and healthcare operations"),
    ("engineering", "Engineering", "engineering", "technical design, infrastructure, product, and systems work"),
    ("psychology", "Psychology", "social science", "human behavior, research, counseling-adjacent, and service roles"),
    ("biology", "Biology", "science", "life sciences, lab work, health pathways, and research preparation"),
    ("accounting", "Accounting", "business", "audit, tax, corporate finance, and compliance roles"),
    ("finance", "Finance", "business", "banking, planning, investment, and corporate finance work"),
    ("education", "Education", "education", "teaching, instructional support, and school leadership pathways"),
    ("criminal-justice", "Criminal Justice", "public service", "public safety, legal support, and policy-adjacent work"),
    ("information-technology", "Information Technology", "technology", "networking, cloud, support, and enterprise systems roles"),
    ("marketing", "Marketing", "business", "brand, growth, analytics, and customer strategy work"),
    ("healthcare-administration", "Healthcare Administration", "healthcare", "health systems, operations, and care management roles"),
    ("data-science", "Data Science", "technology", "analytics, machine learning, and evidence-driven decision support"),
    ("cybersecurity", "Cybersecurity", "technology", "security operations, risk, infrastructure, and compliance roles"),
    ("mechanical-engineering", "Mechanical Engineering", "engineering", "machines, energy, manufacturing, and product design"),
    ("electrical-engineering", "Electrical Engineering", "engineering", "electronics, power, embedded systems, and communications"),
    ("public-health", "Public Health", "healthcare", "population health, prevention, policy, and health education"),
    ("social-work", "Social Work", "public service", "community support, case management, and human services"),
    ("communications", "Communications", "liberal arts", "media, writing, public relations, and organizational messaging"),
    ("economics", "Economics", "social science", "markets, policy, analysis, and business strategy"),
    ("political-science", "Political Science", "social science", "government, policy, law-adjacent, and civic roles"),
    ("graphic-design", "Graphic Design", "creative", "visual communication, product, brand, and digital media work"),
    ("computer-information-systems", "Computer Information Systems", "technology", "business systems, analytics, and technology operations"),
    ("pre-med-health-sciences", "Pre-Med and Health Sciences", "healthcare", "health preparation, science coursework, and clinical pathways"),
]


def slugify(value):
    value = value.lower().replace("&", "and")
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def esc(value):
    return html.escape(str(value), quote=True)


def money(value):
    if value is None:
        return "Not reported"
    if value >= 1000:
        return f"${round(value / 1000):.0f}K"
    return f"${value:,.0f}"


def percent(value):
    if value is None:
        return "Not reported"
    return f"{round(value * 100):.0f}%"


def ownership_label(value):
    return {1: "Public", 2: "Private nonprofit", 3: "Private for-profit"}.get(value, "College")


def score_school(school):
    net = school.get("net_price")
    earnings = school.get("earnings")
    debt = school.get("debt")
    grad = school.get("graduation_rate")
    score = 50
    if earnings:
        score += min(22, max(-8, (earnings - 45000) / 2500))
    if net:
        score += min(16, max(-18, (26000 - net) / 1600))
    if debt and earnings:
        score += min(12, max(-14, (0.45 - (debt / earnings)) * 38))
    elif debt:
        score += max(-10, (23000 - debt) / 2500)
    if grad:
        score += min(14, max(-16, (grad - 0.55) * 40))
    return int(max(1, min(99, round(score))))


def value_label(score):
    if score >= 85:
        return "Excellent Value"
    if score >= 70:
        return "Good Value"
    if score >= 55:
        return "Fair Value"
    return "High Cost Risk"


def insight_for(school):
    parts = []
    if school.get("net_price") is not None:
        parts.append(f"average net price is {money(school['net_price'])}")
    if school.get("earnings") is not None:
        parts.append(f"reported median earnings are {money(school['earnings'])}")
    if school.get("debt") is not None:
        parts.append(f"median completer debt is {money(school['debt'])}")
    if school.get("graduation_rate") is not None:
        parts.append(f"the graduation rate is {percent(school['graduation_rate'])}")
    if not parts:
        return "TuitionLuma can help compare this school when more cost and outcome fields are available."
    return "TuitionLuma weighs the tradeoff: " + ", ".join(parts[:-1]) + (", and " if len(parts) > 1 else "") + parts[-1] + "."


def fetch_schools():
    api_key = os.environ.get("COLLEGE_SCORECARD_API_KEY") or os.environ.get("WEBSITE_COLLEGE_SCORECARD_API_KEY") or "DEMO_KEY"
    params = {
        "api_key": api_key,
        "per_page": "50",
        "school.operating": "1",
        "school.degrees_awarded.predominant": "3",
        "latest.student.size__range": "5000..",
        "sort": "latest.student.size:desc",
        "fields": ",".join(SCHOOL_FIELDS),
    }
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=30) as response:
        raw = json.load(response)["results"]
    schools = []
    for item in raw:
        school = {
            "id": item.get("id"),
            "name": item.get("school.name"),
            "city": item.get("school.city"),
            "state": item.get("school.state"),
            "ownership": ownership_label(item.get("school.ownership")),
            "student_size": item.get("latest.student.size"),
            "net_price": item.get("latest.cost.avg_net_price.overall"),
            "earnings": item.get("latest.earnings.10_yrs_after_entry.median"),
            "graduation_rate": item.get("latest.completion.completion_rate_4yr_150nt"),
            "debt": item.get("latest.aid.median_debt.completers.overall"),
            "admission_rate": item.get("latest.admissions.admission_rate.overall"),
            "attendance_cost": item.get("latest.cost.attendance.academic_year"),
            "tuition_in_state": item.get("latest.cost.tuition.in_state"),
            "tuition_out_state": item.get("latest.cost.tuition.out_of_state"),
        }
        school["slug"] = slugify(school["name"])
        school["luma_score"] = score_school(school)
        school["value_label"] = value_label(school["luma_score"])
        schools.append(school)
    data_dir = ROOT / "data"
    data_dir.mkdir(exist_ok=True)
    (data_dir / "schools.json").write_text(json.dumps(schools, indent=2) + "\n")
    return schools


def layout(title, description, canonical, body, schema):
    og_title = title.replace(" | TuitionLuma", "")
    return f"""<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{esc(title)}</title>
    <meta name="description" content="{esc(description)}">
    <meta name="robots" content="index,follow">
    <link rel="canonical" href="{esc(canonical)}">
    <meta property="og:site_name" content="TuitionLuma">
    <meta property="og:type" content="article">
    <meta property="og:title" content="{esc(og_title)}">
    <meta property="og:description" content="{esc(description)}">
    <meta property="og:url" content="{esc(canonical)}">
    <meta property="og:image" content="{SITE_URL}/assets/tuitionluma-cap-icon.png">
    <meta property="og:image:width" content="1024">
    <meta property="og:image:height" content="1024">
    <meta property="og:image:alt" content="TuitionLuma graduation cap app icon">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{esc(og_title)}">
    <meta name="twitter:description" content="{esc(description)}">
    <meta name="twitter:image" content="{SITE_URL}/assets/tuitionluma-cap-icon.png">
    <link rel="icon" href="/assets/tuitionluma-cap-icon.png">
    <link rel="apple-touch-icon" href="/assets/tuitionluma-cap-icon.png">
    <link rel="stylesheet" href="/styles.css">
    <script type="application/ld+json">{json.dumps(schema, separators=(",", ":"))}</script>
  </head>
  <body>
    {site_header()}
    {body}
    {site_footer()}
  </body>
</html>
"""


def site_header():
    return """<header class="site-header">
      <nav class="nav" aria-label="Main navigation">
        <a class="brand" href="/"><img src="/assets/tuitionluma-cap-icon.png" alt=""><span>TuitionLuma</span></a>
        <div class="nav-links">
          <a href="/college-cost/">Schools</a>
          <a href="/compare/">Compare</a>
          <a href="/programs/">Programs</a>
          <a href="/support/">Support</a>
          <a href="/accessibility/">Accessibility</a>
          <a href="/privacy/">Privacy</a>
        </div>
      </nav>
    </header>"""


def site_footer():
    return """<footer class="site-footer">
      <div><strong>TuitionLuma</strong><span>College Decision Assistant by Incisive Labs LLC</span></div>
      <div class="footer-links">
        <a href="/college-cost/">Schools</a>
        <a href="/compare/">Comparisons</a>
        <a href="/programs/">Programs</a>
        <a href="/support/">Support</a>
        <a href="/privacy/">Privacy</a>
        <a href="/terms/">Terms</a>
      </div>
    </footer>"""


def breadcrumbs(items):
    html_items = []
    schema_items = []
    for index, (name, url) in enumerate(items, start=1):
        html_items.append(f'<a href="{esc(url)}">{esc(name)}</a>')
        schema_items.append({"@type": "ListItem", "position": index, "name": name, "item": SITE_URL + url})
    return " / ".join(html_items), {
        "@type": "BreadcrumbList",
        "itemListElement": schema_items,
    }


def schema_graph(page_type, canonical, title, description, crumbs):
    return {
        "@context": "https://schema.org",
        "@graph": [
            {"@type": "Organization", "@id": "https://incisive-labs.pages.dev/#organization", "name": "Incisive Labs LLC", "url": "https://incisive-labs.pages.dev/"},
            {"@type": page_type, "url": canonical, "name": title, "description": description, "publisher": {"@id": "https://incisive-labs.pages.dev/#organization"}},
            crumbs,
        ],
    }


def stat_cards(school):
    stats = [
        ("Average net price", money(school.get("net_price")), "School-wide historical average"),
        ("Median earnings", money(school.get("earnings")), "10 years after entry"),
        ("Median debt", money(school.get("debt")), "Completers where reported"),
        ("Graduation rate", percent(school.get("graduation_rate")), "150% of normal time"),
    ]
    return "".join(f'<article class="seo-stat"><span>{esc(label)}</span><strong>{esc(value)}</strong><p>{esc(note)}</p></article>' for label, value, note in stats)


def related_school_links(school, schools, count=4):
    same_state = [s for s in schools if s["state"] == school["state"] and s["slug"] != school["slug"]]
    scored = sorted(same_state or [s for s in schools if s["slug"] != school["slug"]], key=lambda s: abs(s["luma_score"] - school["luma_score"]))
    return scored[:count]


def program_links(count=5, offset=0):
    selected = [PROGRAMS[(offset + i) % len(PROGRAMS)] for i in range(count)]
    return selected


def school_page(school, schools):
    canonical = f"{SITE_URL}/college-cost/{school['slug']}/"
    title = f"{school['name']} Cost, Outcomes, Debt & Luma Score | TuitionLuma"
    description = f"Compare {school['name']} cost, average net price, student debt, earnings, graduation rate, and overall value with TuitionLuma."
    crumb_html, crumb_schema = breadcrumbs([("Home", "/"), ("College cost", "/college-cost/"), (school["name"], f"/college-cost/{school['slug']}/")])
    related = related_school_links(school, schools)
    related_programs = program_links(5, school["luma_score"] % len(PROGRAMS))
    intro_variants = [
        f"{school['name']} is a {school['ownership'].lower()} institution in {school['city']}, {school['state']}. This guide brings cost, debt, completion, and earnings signals into one decision-focused view.",
        f"For families comparing {school['city']} college options, {school['name']} should be reviewed through more than tuition alone. The useful question is how cost lines up with outcomes.",
        f"{school['name']} can look different depending on aid, residency, borrowing, and academic path. TuitionLuma summarizes the reported data points that matter most for a practical first pass.",
    ]
    intro = intro_variants[school["luma_score"] % len(intro_variants)]
    body = f"""<main class="seo-page">
      <nav class="breadcrumbs" aria-label="Breadcrumb">{crumb_html}</nav>
      <section class="seo-hero-card">
        <div>
          <p class="eyebrow">{esc(school['city'])}, {esc(school['state'])}</p>
          <h1>{esc(school['name'])} cost, outcomes, and value</h1>
          <p class="lead">{esc(intro)}</p>
        </div>
        <aside class="seo-score-card">
          <span>Luma Score</span>
          <strong>{school['luma_score']}</strong>
          <p>{esc(school['value_label'])}</p>
        </aside>
      </section>
      <section class="seo-stat-grid">{stat_cards(school)}</section>
      <section class="seo-content-grid">
        <article><h2>Cost overview</h2><p>{esc(school['name'])} reports an average net price of {money(school.get('net_price'))}. Tuition is {money(school.get('tuition_in_state'))} for in-state students and {money(school.get('tuition_out_state'))} for out-of-state students where reported. Families should compare this against grants, scholarships, housing, and likely borrowing.</p></article>
        <article><h2>Outcomes overview</h2><p>Reported median earnings are {money(school.get('earnings'))}. This is not a guaranteed salary, but it helps compare the long-term payoff side of the college decision.</p></article>
        <article><h2>Debt discussion</h2><p>Median debt for completers is {money(school.get('debt'))}. A lower debt load can make monthly repayment easier after graduation, especially when earnings are still uncertain.</p></article>
        <article><h2>Graduation discussion</h2><p>The reported graduation rate is {percent(school.get('graduation_rate'))}. Completion matters because extra time in school can increase tuition, living costs, and borrowing.</p></article>
      </section>
      <section class="insight-panel"><h2>TuitionLuma insight</h2><p>{esc(insight_for(school))}</p></section>
      <section><h2>Who should consider this school?</h2><p>{esc(school['name'])} may be worth a closer look for students who want a {esc(school['ownership'].lower())} option and plan to compare personalized aid, debt, and program outcomes before committing. It may require extra review if your estimated net cost is far above the reported average or if your intended program has limited outcome data.</p></section>
      <section class="related-grid">
        <article><h2>Related schools</h2>{link_list([(s['name'], f"/college-cost/{s['slug']}/") for s in related])}</article>
        <article><h2>Related programs</h2>{link_list([(p[1], f"/programs/{p[0]}/") for p in related_programs])}</article>
      </section>
      {cta_block()}
    </main>"""
    return layout(title, description, canonical, body, schema_graph("CollegeOrUniversity", canonical, title, description, crumb_schema))


def link_list(items):
    return "<ul class=\"seo-link-list\">" + "".join(f'<li><a href="{esc(url)}">{esc(name)}</a></li>' for name, url in items) + "</ul>"


def cta_block():
    return """<section class="seo-cta">
        <div><p class="eyebrow">Plan with TuitionLuma</p><h2>Model your real college decision.</h2><p>Download TuitionLuma to compare cost, aid, student debt, school outcomes, and program value in one mobile planning workspace.</p></div>
        <a class="button primary" href="/">Download TuitionLuma</a>
      </section>"""


def comparison_reasons(a, b):
    winner = a if a["luma_score"] >= b["luma_score"] else b
    other = b if winner is a else a
    reasons = []
    if winner.get("net_price") and other.get("net_price") and winner["net_price"] < other["net_price"]:
        reasons.append("lower reported average net price")
    if winner.get("earnings") and other.get("earnings") and winner["earnings"] > other["earnings"]:
        reasons.append("higher reported median earnings")
    if winner.get("debt") and other.get("debt") and winner["debt"] < other["debt"]:
        reasons.append("lower reported median debt")
    if winner.get("graduation_rate") and other.get("graduation_rate") and winner["graduation_rate"] > other["graduation_rate"]:
        reasons.append("higher reported graduation rate")
    if not reasons:
        reasons.append("the stronger combined Luma Score in this sample")
    return winner, reasons


def comparison_page(a, b):
    slug = f"{a['slug']}-vs-{b['slug']}"
    canonical = f"{SITE_URL}/compare/{slug}/"
    title = f"{a['name']} vs {b['name']}: Cost, Debt & ROI | TuitionLuma"
    description = f"Compare {a['name']} and {b['name']} by cost, earnings, graduation rate, debt, Luma Score, and student value tradeoffs."
    crumb_html, crumb_schema = breadcrumbs([("Home", "/"), ("Compare", "/compare/"), (f"{a['name']} vs {b['name']}", f"/compare/{slug}/")])
    winner, reasons = comparison_reasons(a, b)
    reason_text = ", ".join(reasons)
    body = f"""<main class="seo-page">
      <nav class="breadcrumbs" aria-label="Breadcrumb">{crumb_html}</nav>
      <section class="seo-hero-card compare-hero">
        <div><p class="eyebrow">College comparison</p><h1>{esc(a['name'])} vs {esc(b['name'])}</h1><p class="lead">This comparison focuses on the numbers families usually need first: cost, earnings, graduation, debt, and overall value.</p></div>
        <aside class="seo-score-card"><span>Recommended choice</span><strong>{esc(short_name(winner['name']))}</strong><p>{esc(reason_text.capitalize())}.</p></aside>
      </section>
      <section class="comparison-table" aria-label="College comparison data">
        {comparison_row('Luma Score', str(a['luma_score']), str(b['luma_score']), a['luma_score'] >= b['luma_score'])}
        {comparison_row('Average net price', money(a.get('net_price')), money(b.get('net_price')), lower_better(a.get('net_price'), b.get('net_price')))}
        {comparison_row('Median earnings', money(a.get('earnings')), money(b.get('earnings')), higher_better(a.get('earnings'), b.get('earnings')))}
        {comparison_row('Median debt', money(a.get('debt')), money(b.get('debt')), lower_better(a.get('debt'), b.get('debt')))}
        {comparison_row('Graduation rate', percent(a.get('graduation_rate')), percent(b.get('graduation_rate')), higher_better(a.get('graduation_rate'), b.get('graduation_rate')))}
      </section>
      <section class="seo-content-grid">
        <article><h2>Cost comparison</h2><p>{esc(a['name'])} reports an average net price of {money(a.get('net_price'))}, while {esc(b['name'])} reports {money(b.get('net_price'))}. The better choice depends on your aid package, residency, housing, and borrowing plan.</p></article>
        <article><h2>Earnings comparison</h2><p>Reported median earnings are {money(a.get('earnings'))} for {esc(a['name'])} and {money(b.get('earnings'))} for {esc(b['name'])}. Use this as a directional outcome signal, not a salary promise.</p></article>
        <article><h2>Debt comparison</h2><p>Median completer debt is {money(a.get('debt'))} at {esc(a['name'])} and {money(b.get('debt'))} at {esc(b['name'])}. Lower debt can reduce repayment pressure after graduation.</p></article>
        <article><h2>Graduation comparison</h2><p>Graduation rates are {percent(a.get('graduation_rate'))} and {percent(b.get('graduation_rate'))}. Completion is an important affordability factor because extra terms can add cost.</p></article>
      </section>
      <section class="insight-panel"><h2>TuitionLuma recommendation</h2><p>Based on the available static sample, {esc(winner['name'])} looks stronger because of {esc(reason_text)}. Before deciding, compare your actual financial aid offers and intended program outcomes.</p></section>
      <section><h2>Who should use this comparison?</h2><p>This comparison is most useful for students choosing between two known options and families trying to understand the tradeoff between price, debt, completion, and earnings. It should be paired with actual aid letters before making a final decision.</p></section>
      <section class="related-grid">
        <article><h2>Explore each school</h2>{link_list([(a['name'], f"/college-cost/{a['slug']}/"), (b['name'], f"/college-cost/{b['slug']}/")])}</article>
        <article><h2>Related programs</h2>{link_list([(p[1], f"/programs/{p[0]}/") for p in program_links(5, a['luma_score'] + b['luma_score'])])}</article>
      </section>
      {cta_block()}
    </main>"""
    return layout(title, description, canonical, body, schema_graph("WebPage", canonical, title, description, crumb_schema))


def lower_better(a, b):
    return a is not None and b is not None and a <= b


def higher_better(a, b):
    return a is not None and b is not None and a >= b


def comparison_row(label, a, b, first_wins):
    first = " winner" if first_wins else ""
    second = "" if first_wins else " winner"
    return f'<div class="compare-row"><span>{esc(label)}</span><strong class="{first.strip()}">{esc(a)}</strong><strong class="{second.strip()}">{esc(b)}</strong></div>'


def short_name(name):
    replacements = {
        "Southern New Hampshire University": "SNHU",
        "Western Governors University": "WGU",
        "University of Phoenix-Arizona": "U. Phoenix",
        "Arizona State University Campus Immersion": "Arizona State",
    }
    return replacements.get(name, name.replace("University of ", "U. ").replace("California State University-", "Cal State "))


def program_page(program, schools):
    slug, name, category, career = program
    canonical = f"{SITE_URL}/programs/{slug}/"
    title = f"{name} College ROI, Cost & Debt Guide | TuitionLuma"
    description = f"Explore {name} degree planning with TuitionLuma: career overview, cost, debt, earnings signals, example schools, and ROI considerations."
    crumb_html, crumb_schema = breadcrumbs([("Home", "/"), ("Programs", "/programs/"), (name, f"/programs/{slug}/")])
    examples = sorted(schools, key=lambda s: (s.get("earnings") or 0, s["luma_score"]), reverse=True)[(len(slug) % 10):(len(slug) % 10) + 5]
    earnings_values = [s["earnings"] for s in examples if s.get("earnings")]
    typical = money(int(statistics.median(earnings_values))) if earnings_values else "school-dependent"
    debt_values = [s["debt"] for s in examples if s.get("debt")]
    debt_note = money(int(statistics.median(debt_values))) if debt_values else "not consistently reported"
    body = f"""<main class="seo-page">
      <nav class="breadcrumbs" aria-label="Breadcrumb">{crumb_html}</nav>
      <section class="seo-hero-card">
        <div><p class="eyebrow">{esc(category)} planning</p><h1>{esc(name)} degree cost, outcomes, and ROI</h1><p class="lead">{esc(name)} can lead toward {esc(career)}. TuitionLuma helps families compare the cost and outcome side of that path before choosing a school.</p></div>
        <aside class="seo-score-card"><span>Planning focus</span><strong>ROI</strong><p>Compare salary, debt, and completion data where reported.</p></aside>
      </section>
      <section class="seo-content-grid">
        <article><h2>Cost overview</h2><p>{esc(name)} affordability depends on the school, credential level, time to completion, housing, and aid. Compare net price and debt together instead of judging the program by tuition alone.</p></article>
        <article><h2>Career overview</h2><p>{esc(name)} students often compare schools by curriculum fit, completion support, internship or clinical pathways, and the cost required to reach the credential.</p></article>
        <article><h2>Outcomes and typical earnings</h2><p>Program-level earnings vary by school and reporting availability. Among the example schools linked here, school-wide reported median earnings center around {typical}; use TuitionLuma to check school and program data together.</p></article>
        <article><h2>Debt considerations</h2><p>Debt should be compared against expected earnings and time to completion. The example-school median debt signal is {debt_note}, but your borrowing can change with aid, scholarships, family contribution, and housing.</p></article>
        <article><h2>Graduation discussion</h2><p>Completion rates matter for {esc(name)} because extra terms can add living costs and delay earnings. TuitionLuma helps families compare completion signals alongside cost and debt.</p></article>
        <article><h2>ROI discussion</h2><p>A stronger {esc(name)} plan usually combines manageable net cost, clear completion odds, reasonable debt, and earnings that support repayment after graduation.</p></article>
      </section>
      <section class="insight-panel"><h2>TuitionLuma planning recommendation</h2><p>Start with schools that report usable cost and outcome data, then narrow by affordability, debt comfort, and whether the program path matches your goals. Avoid choosing on sticker price or brand alone.</p></section>
      <section><h2>Who should consider this program?</h2><p>{esc(name)} may fit students who are interested in {esc(career)} and want to compare programs through cost, debt, completion, and earnings signals before committing to a school.</p></section>
      <section class="related-grid">
        <article><h2>Example schools to compare</h2>{link_list([(s['name'], f"/college-cost/{s['slug']}/") for s in examples])}</article>
        <article><h2>Related programs</h2>{link_list([(p[1], f"/programs/{p[0]}/") for p in program_links(5, len(name)) if p[0] != slug])}</article>
      </section>
      {cta_block()}
    </main>"""
    return layout(title, description, canonical, body, schema_graph("WebPage", canonical, title, description, crumb_schema))


def index_page(kind, title, description, items):
    canonical = f"{SITE_URL}/{kind}/"
    crumb_html, crumb_schema = breadcrumbs([("Home", "/"), (title, f"/{kind}/")])
    body = f"""<main class="seo-page">
      <nav class="breadcrumbs" aria-label="Breadcrumb">{crumb_html}</nav>
      <section class="seo-hero-card"><div><p class="eyebrow">TuitionLuma guide library</p><h1>{esc(title)}</h1><p class="lead">{esc(description)}</p></div></section>
      <section>{link_list(items)}</section>
      {cta_block()}
    </main>"""
    return layout(f"{title} | TuitionLuma", description, canonical, body, schema_graph("CollectionPage", canonical, title, description, crumb_schema))


def write(path, content):
    path.mkdir(parents=True, exist_ok=True)
    (path / "index.html").write_text(content)


def clean_generated_dirs():
    for folder in ["college-cost", "compare", "programs"]:
        target = ROOT / folder
        if target.exists():
            for child in target.glob("**/*"):
                if child.is_file():
                    child.unlink()
            for child in sorted(target.glob("**/*"), reverse=True):
                if child.is_dir():
                    child.rmdir()


def write_sitemap(urls):
    static_urls = [
        ("/", "1.0", "weekly"),
        ("/support/", "0.8", "monthly"),
        ("/accessibility/", "0.6", "monthly"),
        ("/college-cost-comparison/", "0.9", "monthly"),
        ("/net-price-calculator/", "0.9", "monthly"),
        ("/college-roi-by-major/", "0.9", "monthly"),
        ("/college-affordability-score/", "0.9", "monthly"),
        ("/parents/", "0.85", "monthly"),
        ("/students/", "0.85", "monthly"),
        ("/privacy/", "0.5", "monthly"),
        ("/terms/", "0.5", "monthly"),
    ]
    all_urls = [(SITE_URL + path, priority, freq) for path, priority, freq in static_urls] + urls
    body = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for loc, priority, freq in all_urls:
        body.append("  <url>")
        body.append(f"    <loc>{esc(loc)}</loc>")
        body.append(f"    <lastmod>{TODAY}</lastmod>")
        body.append(f"    <changefreq>{freq}</changefreq>")
        body.append(f"    <priority>{priority}</priority>")
        body.append("  </url>")
    body.append("</urlset>")
    (ROOT / "sitemap.xml").write_text("\n".join(body) + "\n")


def main():
    schools = fetch_schools()
    clean_generated_dirs()
    urls = []

    for school in schools:
        write(ROOT / "college-cost" / school["slug"], school_page(school, schools))
        urls.append((f"{SITE_URL}/college-cost/{school['slug']}/", "0.72", "monthly"))

    pairs = [(schools[i], schools[i + 1]) for i in range(0, 50, 2)]
    for a, b in pairs:
        slug = f"{a['slug']}-vs-{b['slug']}"
        write(ROOT / "compare" / slug, comparison_page(a, b))
        urls.append((f"{SITE_URL}/compare/{slug}/", "0.68", "monthly"))

    for program in PROGRAMS:
        write(ROOT / "programs" / program[0], program_page(program, schools))
        urls.append((f"{SITE_URL}/programs/{program[0]}/", "0.68", "monthly"))

    write(ROOT / "college-cost", index_page("college-cost", "College Cost Guides", "Browse TuitionLuma school cost guides with average net price, debt, graduation, earnings, and value tradeoffs.", [(s["name"], f"/college-cost/{s['slug']}/") for s in schools]))
    write(ROOT / "compare", index_page("compare", "College Comparison Guides", "Compare colleges side by side by cost, earnings, graduation, debt, and Luma Score.", [(f"{a['name']} vs {b['name']}", f"/compare/{a['slug']}-vs-{b['slug']}/") for a, b in pairs]))
    write(ROOT / "programs", index_page("programs", "Program ROI Guides", "Explore broad program paths by career direction, debt considerations, earnings signals, and ROI planning.", [(p[1], f"/programs/{p[0]}/") for p in PROGRAMS]))
    urls.extend([
        (f"{SITE_URL}/college-cost/", "0.82", "weekly"),
        (f"{SITE_URL}/compare/", "0.78", "weekly"),
        (f"{SITE_URL}/programs/", "0.78", "weekly"),
    ])
    write_sitemap(urls)
    print(json.dumps({"school_pages": len(schools), "comparison_pages": len(pairs), "program_pages": len(PROGRAMS), "sitemap_urls": len(urls) + 11}, indent=2))


if __name__ == "__main__":
    main()
