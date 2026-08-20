"""Generate the one page Bellabeat executive brief."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import letter
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "EXECUTIVE_BRIEF.pdf"

INK = HexColor("#0F172A")
MUTED = HexColor("#64748B")
TEAL = HexColor("#0F766E")
TEAL_DARK = HexColor("#0B2F36")
CORAL = HexColor("#F97360")
GOLD = HexColor("#EAB308")
PALE = HexColor("#F1F5F9")
LINE = HexColor("#E2E8F0")
WHITE = HexColor("#FFFFFF")


def wrapped_lines(text: str, font: str, size: float, width: float) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if stringWidth(candidate, font, size) <= width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_text(
    pdf: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    width: float,
    font: str = "Helvetica",
    size: float = 8.5,
    color=MUTED,
    leading: float = 11,
) -> float:
    pdf.setFillColor(color)
    pdf.setFont(font, size)
    for line in wrapped_lines(text, font, size, width):
        pdf.drawString(x, y, line)
        y -= leading
    return y


def section_label(pdf: canvas.Canvas, text: str, x: float, y: float) -> None:
    pdf.setFillColor(TEAL)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawString(x, y, text.upper())


def numbered_item(
    pdf: canvas.Canvas,
    number: int,
    title: str,
    body: str,
    x: float,
    y: float,
    width: float,
    accent=TEAL,
) -> float:
    pdf.setFillColor(accent)
    pdf.circle(x + 8, y - 2, 8, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 7)
    pdf.drawCentredString(x + 8, y - 4.3, str(number))
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(x + 23, y, title)
    return draw_text(pdf, body, x + 23, y - 13, width - 23, size=7.7, leading=9.5)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf = canvas.Canvas(
        str(OUTPUT), pagesize=letter, pageCompression=1, invariant=1
    )
    width, height = letter
    pdf.setTitle("Bellabeat Usage Intelligence Executive Brief")
    pdf.setAuthor("Kazmir Fahrier")
    pdf.setSubject("Wearable usage analytics and product experiment recommendations")

    pdf.setFillColor(TEAL_DARK)
    pdf.rect(0, height - 126, width, 126, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 22)
    pdf.drawString(38, height - 51, "Bellabeat Usage Intelligence")
    pdf.setFont("Helvetica", 10)
    pdf.setFillColor(HexColor("#CCFBF1"))
    pdf.drawString(38, height - 70, "Executive brief | Evidence led product analytics")
    draw_text(
        pdf,
        "Business question: What can this wearable usage sample support about activity patterns, product opportunities, and the evidence needed before rollout?",
        38,
        height - 92,
        455,
        font="Helvetica",
        size=8.3,
        color=WHITE,
        leading=10.5,
    )
    pdf.setFillColor(CORAL)
    pdf.roundRect(505, height - 98, 69, 30, 7, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawCentredString(539.5, height - 80, "APR TO MAY")
    pdf.setFont("Helvetica", 6.5)
    pdf.drawCentredString(539.5, height - 90, "2016 SAMPLE")

    cards = [
        ("33", "activity participants", TEAL),
        ("7,556", "participant weighted steps", CORAL),
        ("31.1%", "days reaching 10k steps", GOLD),
    ]
    card_y = height - 213
    card_w = 166
    for index, (value, label, accent) in enumerate(cards):
        x = 38 + index * 179
        pdf.setFillColor(WHITE)
        pdf.setStrokeColor(LINE)
        pdf.roundRect(x, card_y, card_w, 66, 8, fill=1, stroke=1)
        pdf.setFillColor(accent)
        pdf.rect(x, card_y + 62, card_w, 4, fill=1, stroke=0)
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 19)
        pdf.drawString(x + 14, card_y + 33, value)
        pdf.setFillColor(MUTED)
        pdf.setFont("Helvetica", 7.5)
        pdf.drawString(x + 14, card_y + 17, label)

    left_x, right_x = 38, 321
    section_label(pdf, "What the evidence says", left_x, height - 242)
    y = height - 261
    y = numbered_item(
        pdf, 1, "Saturday activity is highest", "Participant weighted steps peak at 8,400 on Saturday. Hourly activity peaks near 18:00.", left_x, y, 250
    ) - 10
    y = numbered_item(
        pdf, 2, "Sedentary time remains substantial", "The participant weighted mean is 16.63 sedentary hours per recorded day, with a 95% interval from 15.38 to 17.86.", left_x, y, 250, CORAL
    ) - 10
    numbered_item(
        pdf, 3, "Sleep evidence is inconclusive", "The within participant estimate is negative, but its cluster bootstrap interval includes zero. It does not establish an effect.", left_x, y, 250, GOLD
    )

    section_label(pdf, "What Bellabeat should test", right_x, height - 242)
    y = height - 261
    y = numbered_item(
        pdf, 1, "Evening movement prompt", "Randomize a personalized prompt around the evening activity window. Measure incremental steps and prompt opt outs.", right_x, y, 253
    ) - 10
    y = numbered_item(
        pdf, 2, "Weekly progress reflection", "Test attainable, adaptive goals against a neutral summary. Measure goal completion and four week retention.", right_x, y, 253, CORAL
    ) - 10
    numbered_item(
        pdf, 3, "Sleep logging support", "Test education and user controlled reminders. Measure valid sleep logs without increasing notification fatigue.", right_x, y, 253, GOLD
    )

    limit_y = 126
    pdf.setFillColor(PALE)
    pdf.roundRect(38, limit_y, 536, 105, 10, fill=1, stroke=0)
    section_label(pdf, "Decision limits", 54, limit_y + 83)
    limitations = [
        ("Coverage", "33 activity, 24 sleep, and 8 weight participants. Missingness is not random."),
        ("Generalization", "A small 2016 convenience sample cannot represent Bellabeat customers or current behavior."),
        ("Causality", "Observational associations support hypotheses, not product impact claims. Use randomized tests."),
    ]
    for index, (title, body) in enumerate(limitations):
        x = 54 + index * 173
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 8.5)
        pdf.drawString(x, limit_y + 61, title)
        draw_text(pdf, body, x, limit_y + 47, 151, size=7.3, leading=9)

    pdf.setStrokeColor(LINE)
    pdf.line(38, 96, 574, 96)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 7.5)
    pdf.drawString(38, 78, "Method")
    draw_text(
        pdf,
        "Verified source checks in DuckDB, equal participant weighting, cluster bootstrap intervals, and explicit sensitivity analysis.",
        83,
        78,
        385,
        size=7.2,
        leading=8.5,
    )
    pdf.setFillColor(TEAL)
    pdf.setFont("Helvetica-Bold", 7)
    pdf.drawRightString(574, 78, "QUALITY GATE: PASS")
    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica", 6.5)
    pdf.drawString(38, 44, "Source: Fitabase Data 4.12.16 to 5.12.16. Reproducible project outputs provide full definitions and intervals.")
    pdf.drawRightString(574, 44, "Kazmir Fahrier")

    pdf.showPage()
    pdf.save()
    print(f"Executive brief written to {OUTPUT}")


if __name__ == "__main__":
    main()
