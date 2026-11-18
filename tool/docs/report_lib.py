# Word 보고서 서식 도우미 (python-docx)
import re
from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

FONT = '맑은 고딕'
INK = RGBColor(0x22, 0x22, 0x22)
GOLD = RGBColor(0x8A, 0x6A, 0x1F)
MUTED = RGBColor(0x66, 0x66, 0x66)

STATUS = {  # 라벨: (배경, 글자색)
    '실동작': ('DFF0E3', '1E6B34'),
    '화면 동작': ('FFF1D6', '8A5A00'),
    '데모': ('ECECEC', '555555'),
    '신규': ('DCEBFA', '1F4E8C'),
    '목업 데이터': ('F6E3E3', '8C2F2F'),
}


def _font(run, size=None, bold=None, color=None, italic=None):
    run.font.name = FONT
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn('w:rFonts'))
    if rfonts is None:
        rfonts = OxmlElement('w:rFonts')
        rpr.append(rfonts)
    for k in ('w:ascii', 'w:hAnsi', 'w:eastAsia', 'w:cs'):
        rfonts.set(qn(k), FONT)
    if size:
        run.font.size = Pt(size)
    if bold is not None:
        run.font.bold = bold
    if italic is not None:
        run.font.italic = italic
    if color is not None:
        run.font.color.rgb = color


def _shade(cell, hex_fill):
    tcpr = cell._element.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hex_fill)
    tcpr.append(shd)


def _cell_margins(table, top=60, bottom=60, left=90, right=90):
    tblpr = table._element.tblPr
    mar = OxmlElement('w:tblCellMar')
    for side, v in (('top', top), ('left', left), ('bottom', bottom), ('right', right)):
        el = OxmlElement(f'w:{side}')
        el.set(qn('w:w'), str(v))
        el.set(qn('w:type'), 'dxa')
        mar.append(el)
    tblpr.append(mar)


def _repeat_header(row):
    trpr = row._tr.get_or_add_trPr()
    el = OxmlElement('w:tblHeader')
    el.set(qn('w:val'), 'true')
    trpr.append(el)


def _no_split(row):
    trpr = row._tr.get_or_add_trPr()
    el = OxmlElement('w:cantSplit')
    el.set(qn('w:val'), 'true')
    trpr.append(el)


def add_rich(par, text, size=10, color=INK, bold_all=False):
    """**굵게** 표시를 지원하는 문단 채우기"""
    for i, part in enumerate(re.split(r'\*\*', text)):
        if not part:
            continue
        r = par.add_run(part)
        _font(r, size=size, bold=bold_all or (i % 2 == 1), color=color)
    return par


class Report:
    def __init__(self):
        self.doc = Document()
        sec = self.doc.sections[0]
        sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)
        sec.orientation = WD_ORIENT.PORTRAIT
        sec.left_margin = sec.right_margin = Cm(2.0)
        sec.top_margin, sec.bottom_margin = Cm(2.0), Cm(1.8)
        st = self.doc.styles['Normal']
        st.font.name = FONT
        st.font.size = Pt(10)
        st.element.rPr.rFonts.set(qn('w:eastAsia'), FONT)
        st.paragraph_format.space_after = Pt(4)
        st.paragraph_format.line_spacing = 1.25
        for lvl, size, color, before, after in ((1, 16, GOLD, 18, 8), (2, 13, INK, 14, 6), (3, 11, INK, 10, 4)):
            hs = self.doc.styles[f'Heading {lvl}']
            hs.font.name = FONT
            hs.font.size = Pt(size)
            hs.font.bold = True
            hs.font.color.rgb = color
            hs.element.rPr.rFonts.set(qn('w:eastAsia'), FONT)
            hs.paragraph_format.space_before = Pt(before)
            hs.paragraph_format.space_after = Pt(after)
            hs.paragraph_format.keep_with_next = True
        self._footer()

    def _footer(self):
        p = self.doc.sections[0].footer.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run('FIT LINK 1.0.3 중간 결과 보고서 · ')
        _font(r, size=8, color=MUTED)
        r = p.add_run()
        _font(r, size=8, color=MUTED)
        for tag, txt in (('begin', None), (None, 'PAGE'), ('end', None)):
            if tag:
                fc = OxmlElement('w:fldChar')
                fc.set(qn('w:fldCharType'), tag)
                r._r.append(fc)
            else:
                it = OxmlElement('w:instrText')
                it.set(qn('xml:space'), 'preserve')
                it.text = txt
                r._r.append(it)

    # --- 블록 ---
    def title(self, text, sub=None):
        p = self.doc.add_paragraph()
        p.paragraph_format.space_before = Pt(120)
        r = p.add_run(text)
        _font(r, size=26, bold=True, color=INK)
        if sub:
            p = self.doc.add_paragraph()
            r = p.add_run(sub)
            _font(r, size=13, color=GOLD)
        line = self.doc.add_paragraph()
        pbdr = OxmlElement('w:pBdr')
        b = OxmlElement('w:bottom')
        for k, v in (('w:val', 'single'), ('w:sz', '12'), ('w:space', '1'), ('w:color', '8A6A1F')):
            b.set(qn(k), v)
        pbdr.append(b)
        line._p.get_or_add_pPr().append(pbdr)

    def meta(self, rows):
        t = self.table(['항목', '내용'], rows, [3.5, 13.5], header=False, first_col_bold=True)
        return t

    def h1(self, text):
        return self.doc.add_heading(text, level=1)

    def h2(self, text):
        return self.doc.add_heading(text, level=2)

    def h3(self, text):
        return self.doc.add_heading(text, level=3)

    def p(self, text, size=10, color=INK, italic=False, after=4):
        par = self.doc.add_paragraph()
        par.paragraph_format.space_after = Pt(after)
        add_rich(par, text, size=size, color=color)
        if italic:
            for r in par.runs:
                r.font.italic = True
        return par

    def note(self, text):
        """회색 배경 안내 상자"""
        t = self.doc.add_table(rows=1, cols=1)
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        c = t.rows[0].cells[0]
        c.width = Cm(17)
        _shade(c, 'F7F3EA')
        _cell_margins(t, 100, 100, 160, 160)
        c.paragraphs[0].text = ''
        add_rich(c.paragraphs[0], text, size=9.5)
        self.doc.add_paragraph().paragraph_format.space_after = Pt(2)
        return t

    def bullets(self, items, size=10):
        for it in items:
            par = self.doc.add_paragraph(style='List Bullet')
            par.paragraph_format.space_after = Pt(2)
            add_rich(par, it, size=size)

    def numbered(self, items, size=10):
        # Word 자동 번호는 목록끼리 이어지므로, 목록마다 1부터 직접 번호를 붙인다
        for n, it in enumerate(items, 1):
            par = self.doc.add_paragraph()
            pf = par.paragraph_format
            pf.space_after = Pt(2)
            pf.left_indent = Cm(0.75)
            pf.first_line_indent = Cm(-0.5)
            add_rich(par, f'{n}.  ' + it, size=size)

    def table(self, head, rows, widths_cm, header=True, first_col_bold=False, status_col=None, size=9):
        t = self.doc.add_table(rows=0, cols=len(widths_cm))
        t.style = 'Table Grid'
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        t.autofit = False
        _cell_margins(t)

        def fill(row, values, is_head=False):
            _no_split(row)
            for i, (cell, val) in enumerate(zip(row.cells, values)):
                cell.width = Cm(widths_cm[i])
                cell.paragraphs[0].text = ''
                lines = val if isinstance(val, list) else [val]
                for j, line in enumerate(lines):
                    par = cell.paragraphs[0] if j == 0 else cell.add_paragraph()
                    par.paragraph_format.space_after = Pt(1)
                    par.paragraph_format.line_spacing = 1.15
                    if is_head:
                        add_rich(par, line, size=size, bold_all=True, color=RGBColor(0xFF, 0xFF, 0xFF))
                    elif status_col is not None and i == status_col and line in STATUS:
                        bg, fg = STATUS[line]
                        _shade(cell, bg)
                        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
                        add_rich(par, line, size=size, bold_all=True, color=RGBColor.from_string(fg))
                    else:
                        add_rich(par, line, size=size, bold_all=(first_col_bold and i == 0))
                if is_head:
                    _shade(cell, '3A3226')
                elif first_col_bold and i == 0:
                    _shade(cell, 'F7F3EA')

        if header:
            r = t.add_row()
            fill(r, head, is_head=True)
            _repeat_header(r)
        for vals in rows:
            fill(t.add_row(), vals)
        self.doc.add_paragraph().paragraph_format.space_after = Pt(2)
        return t

    def page_break(self):
        self.doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    def toc(self):
        par = self.doc.add_paragraph()
        r = par.add_run()
        for tag, txt in (('begin', None), (None, 'TOC \\o "1-2" \\h \\z \\u'), ('separate', None)):
            if tag:
                fc = OxmlElement('w:fldChar')
                fc.set(qn('w:fldCharType'), tag)
                r._r.append(fc)
            else:
                it = OxmlElement('w:instrText')
                it.set(qn('xml:space'), 'preserve')
                it.text = txt
                r._r.append(it)
        r2 = par.add_run('목차는 Word에서 이 줄을 오른쪽 클릭 → "필드 업데이트"를 누르면 표시됩니다.')
        _font(r2, size=9, color=MUTED, italic=True)
        r3 = par.add_run()
        fc = OxmlElement('w:fldChar')
        fc.set(qn('w:fldCharType'), 'end')
        r3._r.append(fc)
        # 목차 내용은 저장 후 Word로 채운다 (열 때 "필드 업데이트" 질문이 나오지 않게)

    def save(self, path):
        self.doc.save(path)
