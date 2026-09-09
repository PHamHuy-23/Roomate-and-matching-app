# -*- coding: utf-8 -*-
"""
Full Document Generator for Roommate Matching Hub
Outputs: docs/Nhom13_Mohinhhoayeucau.docx
"""

import sys
import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

def create_full_document():
    doc = Document()

    # 1. Page Setup (A4, Margins: Top 2.0cm, Bottom 2.0cm, Left 3.0cm, Right 2.0cm)
    for section in doc.sections:
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        section.top_margin = Cm(2.0)
        section.bottom_margin = Cm(2.0)
        section.left_margin = Cm(3.0)
        section.right_margin = Cm(2.0)
        section.different_first_page_header_footer = True

        # Header & Footer setup for normal pages
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Đồ án Công nghệ Phần mềm — Roommate Matching Hub | Nhóm 13")
        hrun.font.name = 'Times New Roman'
        hrun.font.size = Pt(9)
        hrun.font.italic = True
        hrun.font.color.rgb = RGBColor(120, 120, 120)

        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        frun = fp.add_run("Trang ")
        frun.font.name = 'Times New Roman'
        frun.font.size = Pt(10)
        frun.font.color.rgb = RGBColor(100, 100, 100)
        # Add page number XML field
        fldSimple = parse_xml(r'<w:fldSimple %s w:instr="PAGE"/>' % nsdecls('w'))
        fp._p.append(fldSimple)

    # Styling helper functions
    def set_cell_shading(cell, color_hex):
        shd_xml = f'<w:shd {nsdecls("w")} w:fill="{color_hex}"/>'
        cell._tc.get_or_add_tcPr().append(parse_xml(shd_xml))

    def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
        tcPr.append(tcMar)

    def set_table_borders(table, color="D0D5DD", sz="4", val="single"):
        tblPr = table._tbl.tblPr
        borders_xml = f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:left w:val="none"/>
            <w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:right w:val="none"/>
            <w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:insideV w:val="none"/>
        </w:tblBorders>
        '''
        tblPr.append(parse_xml(borders_xml))

    def set_grid_borders(table, color="B0B0B0", sz="4", val="single"):
        tblPr = table._tbl.tblPr
        borders_xml = f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:left w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:right w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:insideV w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
        </w:tblBorders>
        '''
        tblPr.append(parse_xml(borders_xml))

    def set_box_borders(table, color="1F4E79", sz="6", val="single"):
        tblPr = table._tbl.tblPr
        borders_xml = f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:left w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:right w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:insideH w:val="none"/>
            <w:insideV w:val="none"/>
        </w:tblBorders>
        '''
        tblPr.append(parse_xml(borders_xml))

    def add_p(text="", font_size=13, bold=False, italic=False, color_rgb=(0,0,0), align=WD_ALIGN_PARAGRAPH.JUSTIFY, space_before=0, space_after=4, line_spacing=1.25):
        p = doc.add_paragraph()
        p.alignment = align
        p.paragraph_format.space_before = Pt(space_before)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = line_spacing
        if text:
            r = p.add_run(text)
            r.font.name = 'Times New Roman'
            r.font.size = Pt(font_size)
            r.font.bold = bold
            r.font.italic = italic
            r.font.color.rgb = RGBColor(*color_rgb)
        return p

    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(16)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.keep_with_next = True
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(15)
        r.font.bold = True
        r.font.color.rgb = RGBColor(31, 78, 121)
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(13.5)
        r.font.bold = True
        r.font.color.rgb = RGBColor(46, 117, 182)
        return p

    def add_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.keep_with_next = True
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(13)
        r.font.bold = True
        r.font.color.rgb = RGBColor(0, 0, 0)
        return p

    def format_table_header(row, col_widths, col_names):
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        for idx, name in enumerate(col_names):
            cell = row.cells[idx]
            cell.width = Inches(col_widths[idx])
            set_cell_shading(cell, "1F4E79")
            set_cell_margins(cell, top=120, bottom=120, left=130, right=130)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            r = p.add_run(name)
            r.font.name = 'Times New Roman'
            r.font.size = Pt(10.5)
            r.font.bold = True
            r.font.color.rgb = RGBColor(255, 255, 255)

    def format_table_row(row, col_widths, values, is_even=False, alignments=None, font_size=10.5):
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        bg_color = "F9FAFB" if is_even else "FFFFFF"
        for idx, val in enumerate(values):
            cell = row.cells[idx]
            cell.width = Inches(col_widths[idx])
            set_cell_shading(cell, bg_color)
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            align = alignments[idx] if alignments and idx < len(alignments) else WD_ALIGN_PARAGRAPH.LEFT
            p.alignment = align
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15
            r = p.add_run(str(val))
            r.font.name = 'Times New Roman'
            r.font.size = Pt(font_size)
            r.font.color.rgb = RGBColor(0, 0, 0)

    # ==========================================
    # 1. TRANG BÌA (COVER PAGE)
    # ==========================================
    # Box table border around cover page
    cover_table = doc.add_table(rows=1, cols=1)
    cover_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cover_cell = cover_table.cell(0, 0)
    cover_cell.width = Inches(6.5)
    
    # Elegant double border for cover
    tblPr = cover_table._tbl.tblPr
    borders_xml = f'''
    <w:tblBorders {nsdecls("w")}>
        <w:top w:val="double" w:sz="12" w:space="0" w:color="1F4E79"/>
        <w:left w:val="double" w:sz="12" w:space="0" w:color="1F4E79"/>
        <w:bottom w:val="double" w:sz="12" w:space="0" w:color="1F4E79"/>
        <w:right w:val="double" w:sz="12" w:space="0" w:color="1F4E79"/>
    </w:tblBorders>
    '''
    tblPr.append(parse_xml(borders_xml))
    set_cell_margins(cover_cell, top=280, bottom=280, left=240, right=240)

    cp = cover_cell.paragraphs[0]
    cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cp.paragraph_format.space_before = Pt(10)
    cp.paragraph_format.space_after = Pt(2)
    r = cp.add_run("TRƯỜNG ĐẠI HỌC CÔNG NGHỆ KỸ THUẬT TP.HCM\n")
    r.font.name = 'Times New Roman'
    r.font.size = Pt(13)
    r.font.bold = True
    r.font.color.rgb = RGBColor(31, 78, 121)

    r2 = cp.add_run("KHOA CÔNG NGHỆ THÔNG TIN\n")
    r2.font.name = 'Times New Roman'
    r2.font.size = Pt(13.5)
    r2.font.bold = True
    r2.font.color.rgb = RGBColor(31, 78, 121)

    r_line = cp.add_run("--------------------***--------------------\n\n\n")
    r_line.font.name = 'Times New Roman'
    r_line.font.size = Pt(11)
    r_line.font.color.rgb = RGBColor(150, 150, 150)

    r_rep = cp.add_run("BÁO CÁO MÔN HỌC: CÔNG NGHỆ PHẦN MỀM\n")
    r_rep.font.name = 'Times New Roman'
    r_rep.font.size = Pt(14)
    r_rep.font.bold = True
    r_rep.font.color.rgb = RGBColor(46, 117, 182)

    r_title = cp.add_run("TÀI LIỆU MÔ HÌNH HÓA YÊU CẦU PHẦN MỀM\n\n")
    r_title.font.name = 'Times New Roman'
    r_title.font.size = Pt(18)
    r_title.font.bold = True
    r_title.font.color.rgb = RGBColor(31, 78, 121)

    r_topic_lbl = cp.add_run("ĐỀ TÀI:\n")
    r_topic_lbl.font.name = 'Times New Roman'
    r_topic_lbl.font.size = Pt(12)
    r_topic_lbl.font.bold = True

    r_topic = cp.add_run("XÂY DỰNG ỨNG DỤNG TÌM KIẾM VÀ GHÉP BẠN CÙNG THUÊ TRỌ THEO TIÊU CHÍ\n")
    r_topic.font.name = 'Times New Roman'
    r_topic.font.size = Pt(15)
    r_topic.font.bold = True
    r_topic.font.color.rgb = RGBColor(192, 0, 0) # Highlight Red/Crimson

    r_sub = cp.add_run("(ROOMMATE MATCHING HUB)\n\n\n\n")
    r_sub.font.name = 'Times New Roman'
    r_sub.font.size = Pt(14)
    r_sub.font.bold = True
    r_sub.font.color.rgb = RGBColor(31, 78, 121)

    # Info block
    p_info = cover_cell.add_paragraph()
    p_info.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p_info.paragraph_format.left_indent = Inches(1.0)
    p_info.paragraph_format.line_spacing = 1.3
    
    runs_info = [
        ("Giảng viên hướng dẫn: ", True),
        ("ThS. Giảng viên phụ trách bộ môn\n", False),
        ("Lớp học phần: ", True),
        ("Công nghệ phần mềm\n", False),
        ("Nhóm thực hiện: ", True),
        ("Nhóm 13\n", False),
        ("Danh sách sinh viên:\n", True),
        ("   1. Phạm Quốc Huy        - MSSV: 24110226\n", False),
        ("   2. Trần Quang Huy        - MSSV: 24110228\n", False),
        ("   3. Phan Tiến Đạt         - MSSV: 24110195\n\n\n\n", False)
    ]
    for txt, is_b in runs_info:
        r = p_info.add_run(txt)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(12)
        r.font.bold = is_b

    p_foot = cover_cell.add_paragraph()
    p_foot.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_foot.paragraph_format.space_before = Pt(20)
    p_foot.paragraph_format.space_after = Pt(10)
    rf = p_foot.add_run("TP. HỒ CHÍ MINH — NĂM 2026")
    rf.font.name = 'Times New Roman'
    rf.font.size = Pt(12)
    rf.font.bold = True

    doc.add_page_break()

    # ==========================================
    # MỤC LỤC TỔNG QUAN
    # ==========================================
    add_h1("MỤC LỤC BÁO CÁO")
    
    toc_items = [
        ("PHẦN 1. KHẢO SÁT HIỆN TRẠNG", "Trang 3"),
        ("   1.1. Giới thiệu đề tài & Bối cảnh thực tiễn", "Trang 3"),
        ("   1.2. Hiện trạng quy trình tìm bạn cùng phòng truyền thống", "Trang 3"),
        ("   1.3. Khảo sát các nền tảng công nghệ liên quan trên thị trường", "Trang 4"),
        ("   1.4. Bảng tổng hợp hạn chế của hiện trạng", "Trang 5"),
        ("   1.5. Đề xuất giải pháp hệ thống Roommate Matching Hub", "Trang 6"),
        ("PHẦN 2. LẬP DANH SÁCH YÊU CẦU PHẦN MỀM", "Trang 7"),
        ("   2.1. Bản thuyết minh quy trình nghiệp vụ tổng thể", "Trang 7"),
        ("   2.2. Danh sách yêu cầu chức năng nghiệp vụ theo bộ phận (54 FRs)", "Trang 8"),
        ("   2.3. Các biểu mẫu nghiệp vụ mẫu (Mockup Templates)", "Trang 15"),
        ("   2.4. Danh sách yêu cầu chức năng hệ thống & phân quyền", "Trang 17"),
        ("   2.5. Danh sách yêu cầu phi chức năng (NFRs)", "Trang 18"),
        ("PHẦN 3. TÁC NHÂN VÀ CHỨC NĂNG CỦA PHẦN MỀM", "Trang 20"),
        ("   3.1. Nhận diện các tác nhân hệ thống", "Trang 20"),
        ("   3.2. Bảng 3.1: Nhận diện tác nhân và chức năng phần mềm", "Trang 20"),
        ("   3.3. Bảng 3.2: Chi tiết các tác nhân (Vai trò & Mục đích)", "Trang 22"),
        ("   3.4. Bảng 3.3: Danh sách các chức năng và mô tả chi tiết", "Trang 23"),
        ("PHẦN 4. (CÁC) LƯỢC ĐỒ CHỨC NĂNG & ĐẶC TẢ USE CASE", "Trang 27"),
        ("   4.1. Danh mục 6 Lược đồ Use Case phân hệ", "Trang 27"),
        ("   4.2. Danh sách quan hệ <<include>> và <<extend>>", "Trang 29"),
        ("   4.3. Bảng Ma trận truy vết yêu cầu (Traceability Matrix)", "Trang 31"),
        ("   4.4. Quy tắc nghiệp vụ cốt lõi (Business Rules BR-01 -> BR-07)", "Trang 34"),
        ("   4.5. Đặc tả chi tiết các Use Case cốt lõi", "Trang 36"),
        ("KẾT LUẬN & HƯỚNG PHÁT TRIỂN", "Trang 44")
    ]
    for item, page in toc_items:
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.2
        r1 = p.add_run(item)
        r1.font.name = 'Times New Roman'
        r1.font.size = Pt(11.5)
        if "PHẦN" in item or "KẾT LUẬN" in item:
            r1.font.bold = True
            r1.font.color.rgb = RGBColor(31, 78, 121)
        r_dots = p.add_run(" " + "." * (85 - len(item) * 1) + " ")
        r_dots.font.name = 'Times New Roman'
        r_dots.font.size = Pt(10)
        r_dots.font.color.rgb = RGBColor(180, 180, 180)
        r2 = p.add_run(page)
        r2.font.name = 'Times New Roman'
        r2.font.size = Pt(11)
        r2.font.bold = True

    doc.add_page_break()

    # ==========================================
    # PHẦN 1. KHẢO SÁT HIỆN TRẠNG
    # ==========================================
    add_h1("PHẦN 1. KHẢO SÁT HIỆN TRẠNG")
    
    add_h2("1.1. Giới thiệu đề tài & Bối cảnh thực tiễn")
    add_p("Trong bối cảnh đô thị hóa nhanh chóng và sự tập trung ngày càng đông của các trường đại học, cao đẳng cũng như các khu công nghệ cao tại TP. Hồ Chí Minh (đặc biệt tại khu vực TP. Thủ Đức, Làng Đại học Quốc gia, Quận 5, Quận 10), nhu cầu tìm kiếm chỗ ở và bạn cùng thuê trọ (roommate) của sinh viên và người đi làm trẻ tuổi đang tăng trưởng rất mạnh mẽ.")
    add_p("Đối với phần lớn sinh viên sống xa gia đình, chi phí thuê phòng trọ nguyên căn thường vượt quá khả năng tài chính cá nhân. Việc tìm bạn ở ghép là giải pháp kinh tế tối ưu nhất để chia sẻ tiền phòng, tiền điện, nước, internet và các chi phí sinh hoạt chung. Tuy nhiên, qua quá trình khảo sát thực tế đời sống sinh viên, nhóm nghiên cứu nhận thấy việc tìm người ở ghép hiện nay đang gặp phải rất nhiều trở ngại lớn, tiềm ẩn nguy cơ mâu thuẫn sinh hoạt sâu sắc và rủi ro an toàn cá nhân.")

    add_h2("1.2. Hiện trạng quy trình tìm bạn cùng phòng truyền thống")
    add_p("Hiện nay, quy trình tìm người ở ghép truyền thống của sinh viên diễn ra theo trình tự thủ công sau:")
    add_p("1. Đăng tin tự phát: Người cần tìm bạn cùng phòng soạn một mẩu tin ngắn đăng lên các hội nhóm mạng xã hội (Facebook Groups, Zalo, diễn đàn sinh viên) kèm số điện thoại cá nhân và ảnh phòng (nếu có).")
    add_p("2. Tiếp nhận liên hệ và trao đổi sơ bộ: Những người có nhu cầu sẽ nhắn tin qua Messenger, Zalo hoặc gọi điện trực tiếp để hỏi giá phòng và địa chỉ.")
    add_p("3. Tìm hiểu thói quen dựa trên cảm tính: Hai bên nhắn tin trao đổi vài câu hỏi đơn giản về quê quán, trường học, giờ giấc. Quá trình này không có biểu mẫu tiêu chí chuẩn hóa, các thông tin quan trọng như thói quen thức khuya, mức độ sạch sẽ, hút thuốc, nuôi thú cưng hay mời bạn bè về phòng thường bị bỏ qua hoặc trả lời qua loa.")
    add_p("4. Quyết định ở ghép theo cảm tính: Sau khi gặp mặt xem phòng 1 lần, hai bên đưa ra quyết định ở chung hoàn toàn dựa trên cảm nhận bề ngoài.")
    add_p("Hậu quả thực tế: Chỉ sau 1 đến 2 tháng dọn về ở chung, rất nhiều mâu thuẫn nghiêm trọng phát sinh: người ngủ sớm không chịu được người thức khuya chơi game; người thích ngăn nắp bức xúc vì bạn cùng phòng bừa bộn; bất đồng về việc chia tiền điện nước hay việc dẫn người lạ về phòng. Rất nhiều trường hợp kết thúc bằng việc cãi vã, đơn phương dọn đi và mất tiền cọc phòng trọ.")

    add_h2("1.3. Khảo sát các nền tảng công nghệ liên quan trên thị trường")
    add_p("Để có cái nhìn toàn diện, nhóm đã tiến hành khảo sát các giải pháp công nghệ hiện có trên thị trường Việt Nam:")
    
    add_h3("a) Các website đăng tin bất động sản, phòng trọ (Phongtro123.com, Batdongsan.com.vn)")
    add_p("• Ưu điểm: Cơ sở dữ liệu phòng trọ phong phú, phủ sóng rộng rãi khắp các quận huyện; hỗ trợ lọc cơ bản theo khu vực và mức giá; giao diện quen thuộc.")
    add_p("• Nhược điểm lớn: Chỉ phục vụ mô hình chủ nhà cho thuê nguyên căn hoặc phòng trống; HOÀN TOÀN KHÔNG CÓ chức năng kết nối người ở ghép dựa trên tiêu chí lối sống; thông tin người tìm phòng không được chuẩn hóa; xuất hiện nhiều tin ảo từ môi giới/cò phòng trọ.")

    add_h3("b) Các hội nhóm mạng xã hội (Hội tìm bạn ở ghép Làng ĐH, Phòng trọ & Ở ghép Thủ Đức...)")
    add_p("• Ưu điểm: Hoàn toàn miễn phí, tốc độ tương tác cao, số lượng thành viên đông đảo, dễ tiếp cận sinh viên.")
    add_p("• Nhược điểm lớn: Bài đăng trôi cực nhanh sau vài giờ; thông tin hỗn loạn và thiếu kiểm duyệt; lộ toàn bộ thông tin cá nhân (Số điện thoại, Facebook cá nhân) ngay từ đầu dẫn đến nguy cơ bị quấy rối, lừa đảo đặt cọc phòng ảo; không có bất kỳ công cụ nào để đo lường độ hòa hợp giữa hai người lạ trước khi dọn về ở cùng.")

    add_h2("1.4. Bảng tổng hợp hạn chế của hiện trạng")
    add_p("Dưới đây là bảng phân tích tổng hợp các hạn chế, nguyên nhân và mức độ ảnh hưởng của quy trình tìm người ở ghép hiện nay:")

    # Table 1.1
    t1 = doc.add_table(rows=1, cols=5)
    t1.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t1)
    col_w1 = [0.5, 2.0, 1.8, 1.4, 0.8]
    format_table_header(t1.rows[0], col_w1, ["STT", "Vấn đề tồn tại", "Nguyên nhân gốc rễ", "Hậu quả thực tế", "Mức độ"])
    
    t1_data = [
        ("1", "Khó đánh giá mức độ tương thích về lối sống trước khi ở chung", "Thiếu công cụ đo lường khách quan các tiêu chí: giờ giấc, độ sạch sẽ, hút thuốc, thú cưng", "Mâu thuẫn sinh hoạt gay gắt sau khi dọn vào ở; bỏ cọc, chuyển trọ liên tục", "Cao"),
        ("2", "Lộ số điện thoại và thông tin cá nhân quá sớm", "Không có cơ chế phê duyệt 2 chiều; người dùng phải công khai SĐT trên mạng xã hội", "Bị spam, làm phiền, quấy rối; rủi ro an toàn đối với sinh viên nữ", "Cao"),
        ("3", "Khó so sánh nhiều ứng viên cùng lúc", "Thông tin phân tán rải rác trên bình luận, bài đăng tự do không theo khuôn mẫu", "Mất nhiều tuần trao đổi thủ công; dễ bỏ sót bạn trọ tiềm năng phù hợp", "Trung bình"),
        ("4", "Thiếu cơ sở định lượng để ra quyết định", "Quyết định chỉ dựa trên linh cảm và vài dòng tin nhắn xã giao ngắn ngủi", "Đánh giá sai lệch tính cách đối phương; xung đột khi phân chia trách nhiệm", "Cao"),
        ("5", "Trải nghiệm hẹn xem phòng trọ rủi ro và thiếu minh bạch", "Địa chỉ phòng bị công khai; lịch hẹn trao đổi miệng dễ bị bùng hẹn hoặc lừa đảo", "Mất thời gian đôi bên; rủi ro khi sinh viên đi xem phòng tại các ngõ ngách lạ", "Trung bình")
    ]
    for idx, row_val in enumerate(t1_data):
        row = t1.add_row()
        format_table_row(row, col_w1, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER])

    add_p("\nBảng 1.1: Tổng hợp những hạn chế của hiện trạng tìm người ở ghép truyền thống", font_size=11, italic=True, align=WD_ALIGN_PARAGRAPH.CENTER)

    add_h2("1.5. Đề xuất giải pháp hệ thống Roommate Matching Hub")
    add_p("Để giải quyết triệt để các vấn đề nhức nhối trên, nhóm nghiên cứu đề xuất xây dựng nền tảng chuyên biệt: Nền tảng Tìm kiếm và Ghép bạn cùng thuê trọ theo tiêu chí (Roommate Matching Hub) với 3 trụ cột giải pháp đột phá:")
    add_p("1. Bộ khảo sát tiêu chí phong cách sống 5 chiều: Chuẩn hóa toàn bộ thông tin cá nhân thành hệ thống Tiêu chí cứng (Hard Criteria: Giới tính, Khu vực quận, Khoảng giá phòng) và Tiêu chí mềm (Soft Criteria: Giờ ngủ, Giờ dậy, Mức độ sạch sẽ thang 1-5, Hút thuốc lá, Nuôi thú cưng).")
    add_p("2. Thuật toán tính điểm tương thích Matching Score: Áp dụng công thức tính trọng số đa tiêu chí, tự động phân tích và chấm điểm tương thích chính xác theo thang đo % (0% - 100%) giữa hai ứng viên, kèm giải thích rõ ràng lý do hòa hợp.")
    add_p("3. Cơ chế bảo vệ quyền riêng tư Double Opt-in: Số điện thoại, Email và kênh liên lạc của người dùng được ẩn danh hoàn toàn. Chỉ khi Bên A gửi yêu cầu ghép đôi và Bên B chấp thuận yêu cầu đó (cả 2 bên cùng đồng thuận), hệ thống mới chính thức tạo kết nối và mở thông tin liên lạc.")

    doc.add_page_break()

    # ==========================================
    # PHẦN 2. LẬP DANH SÁCH YÊU CẦU PHẦN MỀM
    # ==========================================
    add_h1("PHẦN 2. LẬP DANH SÁCH YÊU CẦU PHẦN MỀM")
    
    add_h2("2.1. Bản thuyết minh quy trình nghiệp vụ tổng thể")
    add_p("Hệ thống Roommate Matching Hub vận hành khép kín theo toàn bộ vòng đời của người tìm bạn ở ghép:")
    add_p("• Bước 1 - Đăng ký & Khảo sát ban đầu: Người dùng đăng ký tài khoản qua email và hoàn thành khảo sát hồ sơ lối sống 5 chiều (Ngân sách, quận, thói quen ngủ, độ sạch sẽ, hút thuốc, thú cưng).")
    add_p("• Bước 2 - Khám phá & So sánh: Hệ thống chạy thuật toán nền, tự động lọc điều kiện bắt buộc và tính toán % Matching Score. Người dùng xem danh sách gợi ý, có thể đặt 2–3 hồ sơ lên bảng so sánh đối đầu trực quan.")
    add_p("• Bước 3 - Ghép đôi bảo mật (Double Opt-in): Người dùng gửi Match Request kèm lời giới thiệu. Phía bên kia có 7 ngày để phản hồi (Chấp nhận / Từ chối). Trong thời gian Pending, người gửi có thể chủ động hủy yêu cầu.")
    add_p("• Bước 4 - Mở kết nối & Lên lịch hẹn xem phòng: Khi yêu cầu được chấp thuận, kết nối Active được tạo lập. Hai bên có thể tự cấu hình quyền chia sẻ SĐT/Zalo và gửi đề xuất lịch hẹn xem phòng trọ thực tế.")
    add_p("• Bước 5 - Xác nhận kết quả ở ghép: Sau khi xem phòng thực tế, cả hai cùng xác nhận 'Đồng ý ở ghép'. Hệ thống tự động trừ số chỗ trống của bài đăng phòng và chuyển trạng thái hoàn thành.")

    add_h2("2.2. Danh sách yêu cầu chức năng nghiệp vụ theo bộ phận (54 FRs)")
    add_p("Bám sát mẫu chuẩn quy định tại Mau_XDYC.docx, danh sách 54 yêu cầu chức năng được phân loại chi tiết theo từng bộ phận nghiệp vụ, phân định rõ ràng các loại công việc: Lưu Trữ, Tra Cứu, Tính Toán, Kết Xuất:")

    # Define FRs by Department
    departments = [
        ("Bộ phận: Quản lý Tài khoản & Hồ sơ cá nhân", "QLTK", [
            ("1", "Đăng ký tài khoản mới", "Lưu Trữ", "Mật khẩu BCrypt >= 6 ký tự, email duy nhất", "QLTK_BM1", "FR-01"),
            ("2", "Đăng nhập hệ thống", "Tra Cứu", "Cấp mã xác thực JWT Token có thời hạn", "QLTK_BM1", "FR-02"),
            ("3", "Đăng xuất phiên làm việc", "Tra Cứu", "Hủy bỏ session/token hiện hành", "—", "FR-03"),
            ("4", "Đặt lại mật khẩu quên", "Lưu Trữ", "Gửi mã OTP qua email xác thực", "—", "FR-04"),
            ("5", "Cập nhật hồ sơ cá nhân", "Lưu Trữ", "Họ tên, ảnh đại diện, giới tính, SĐT", "QLTK_BM1", "FR-05"),
            ("6", "Xem hồ sơ cá nhân", "Tra Cứu", "Trích xuất toàn bộ dữ liệu đã khai báo", "—", "FR-06"),
            ("7", "Xác minh email người dùng", "Lưu Trữ", "Kích hoạt cờ email_verified = true", "—", "FR-22"),
            ("8", "Thay đổi mật khẩu tài khoản", "Lưu Trữ", "Xác minh mật khẩu cũ trước khi đổi", "—", "FR-23"),
            ("9", "Cập nhật trạng thái tìm trọ", "Lưu Trữ", "Bật/Tắt cờ is_searching để ẩn/hiện hồ sơ", "—", "FR-24"),
            ("10", "Thiết lập quyền chia sẻ liên lạc", "Lưu Trữ", "Chọn mở SĐT, Zalo hay Email cho từng kết nối", "QLKN_BM1", "FR-45")
        ]),
        ("Bộ phận: Khảo sát Tiêu chí & Lối sống", "QLTC", [
            ("1", "Khai báo tiêu chí cứng", "Lưu Trữ", "Giới tính bắt buộc, ngân sách trần, quận mong muốn", "QLTC_BM1", "FR-07"),
            ("2", "Khai báo tiêu chí mềm", "Lưu Trữ", "Giờ ngủ, giờ dậy, độ sạch sẽ (1-5), thuốc lá, thú cưng", "QLTC_BM1", "FR-08"),
            ("3", "Chỉnh sửa tiêu chí khảo sát", "Lưu Trữ", "Cập nhật lại các chỉ số khi thói quen thay đổi", "QLTC_BM1", "FR-09"),
            ("4", "Thiết lập mức ưu tiên tiêu chí", "Lưu Trữ", "Gán trọng số (weights) cho từng tiêu chí mềm", "QLTC_BM1", "FR-25"),
            ("5", "Khai báo thời gian & hạn ở", "Lưu Trữ", "Khoảng ngày có thể dọn vào, thời hạn thuê tối thiểu", "QLTC_BM1", "FR-42")
        ]),
        ("Bộ phận: Tìm kiếm, Khám phá & So sánh hồ sơ", "QLSS", [
            ("1", "Tìm kiếm hồ sơ theo bộ lọc", "Tra Cứu", "Lọc theo khoảng giá, quận, giới tính", "—", "FR-10"),
            ("2", "Xem danh sách ứng viên gợi ý", "Kết Xuất", "Xếp danh sách theo điểm Matching giảm dần", "—", "FR-11"),
            ("3", "Sắp xếp danh sách kết quả", "Tra Cứu", "Sắp xếp theo độ tương thích, giá, khoảng cách", "—", "FR-26"),
            ("4", "Xem phân tích lý do tương thích", "Kết Xuất", "Hiển thị chi tiết tiêu chí trùng khớp và sai lệch", "—", "FR-27"),
            ("5", "Quản lý danh sách yêu thích", "Lưu Trữ", "Lưu bookmark hồ sơ bạn trọ hoặc phòng trọ quan tâm", "—", "FR-39"),
            ("6", "So sánh hồ sơ ứng viên đối đầu", "Kết Xuất", "Hiển thị bảng so sánh 2–3 bạn trọ cạnh nhau", "—", "FR-40"),
            ("7", "Lưu bộ lọc tìm kiếm & theo dõi", "Lưu Trữ", "Lưu điều kiện lọc và đăng ký nhận thông báo", "—", "FR-41")
        ]),
        ("Bộ phận: Matching & Tính toán tương thích", "QLMC", [
            ("1", "Tính Matching Score tự động", "Tính Toán", "Công thức trọng số tổng hợp: Score = ∑(wi * Si)", "—", "FR-12"),
            ("2", "Xem hồ sơ ẩn danh ứng viên", "Tra Cứu", "Hiển thị thông tin lối sống, ẩn SĐT/Email", "—", "FR-13")
        ]),
        ("Bộ phận: Ghép đôi & Yêu cầu kết nối (Double Opt-in)", "QLGD", [
            ("1", "Gửi yêu cầu ghép đôi (Match Request)", "Lưu Trữ", "Tạo Match Request trạng thái PENDING", "QLKN_BM1", "FR-14"),
            ("2", "Chấp nhận yêu cầu ghép đôi", "Lưu Trữ", "Chuyển trạng thái sang ACCEPTED, kích hoạt kết nối", "QLKN_BM1", "FR-15"),
            ("3", "Từ chối yêu cầu ghép đôi", "Lưu Trữ", "Chuyển trạng thái sang REJECTED", "QLKN_BM1", "FR-16"),
            ("4", "Xác nhận Double Opt-in thành công", "Tính Toán", "Kiểm tra sự đồng thuận 2 chiều để tạo Connection", "—", "FR-17"),
            ("5", "Hủy yêu cầu ghép đôi đã gửi", "Lưu Trữ", "Rút lại Match Request khi còn Pending", "—", "FR-28"),
            ("6", "Xem & lọc yêu cầu đã gửi/nhận", "Tra Cứu", "Tách riêng 2 tab Gửi / Nhận, lọc theo trạng thái", "—", "FR-43"),
            ("7", "Tự động hết hạn yêu cầu ghép đôi", "Tính Toán", "Chuyển sang Expired sau 7 ngày không phản hồi", "—", "FR-44")
        ]),
        ("Bộ phận: Quản lý Kết nối & Lịch hẹn xem phòng", "QLKN", [
            ("1", "Mở kết nối liên lạc an toàn", "Kết Xuất", "Hiển thị thông tin liên lạc theo quyền chia sẻ", "QLKN_BM1", "FR-18"),
            ("2", "Xem danh sách bạn trọ đã kết nối", "Tra Cứu", "Danh sách các kết nối Active", "—", "FR-19"),
            ("3", "Hủy kết nối bạn trọ", "Lưu Trữ", "Thu hồi quyền xem liên lạc và hủy lịch hẹn", "—", "FR-29"),
            ("4", "Đề xuất lịch hẹn xem phòng trọ", "Lưu Trữ", "Chọn phòng, ngày giờ, địa điểm gặp", "QLLH_BM1", "FR-47"),
            ("5", "Phản hồi & Quản lý lịch hẹn", "Lưu Trữ", "Chấp nhận / Từ chối / Hủy / Đổi giờ hẹn xem trọ", "QLLH_BM1", "FR-48"),
            ("6", "Xác nhận kết quả ở ghép thành công", "Lưu Trữ", "Cả 2 bên bấm đồng ý; tự động giảm chỗ trống", "—", "FR-49"),
            ("7", "Nhắn tin trao đổi trong kết nối", "Lưu Trữ", "(Optional) Kênh chat trực tiếp nội bộ", "—", "FR-38")
        ]),
        ("Bộ phận: Quản lý Bài đăng tìm phòng & ở ghép", "QLBD", [
            ("1", "Đăng bài tìm bạn ở ghép phòng trọ", "Lưu Trữ", "Tiêu đề, địa chỉ, giá, số lượng cần tìm, ảnh", "QLBD_BM1", "FR-20"),
            ("2", "Xem danh sách bài đăng phòng", "Tra Cứu", "Hiển thị các tin đăng phòng còn trống và đã duyệt", "—", "FR-21"),
            ("3", "Chỉnh sửa bài đăng phòng", "Lưu Trữ", "Cập nhật giá, hình ảnh, thông tin mô tả", "QLBD_BM1", "FR-30"),
            ("4", "Đóng bài đăng phòng trọ", "Lưu Trữ", "Chuyển trạng thái sang CLOSED khi đã đủ người", "—", "FR-31"),
            ("5", "Xem chi tiết bài đăng phòng trọ", "Tra Cứu", "Toàn bộ thông tin phòng, tiện ích, tiền điện nước", "—", "FR-32"),
            ("6", "Tìm kiếm bài đăng phòng theo bộ lọc", "Tra Cứu", "Lọc theo khu vực, tầm giá, số chỗ, tiện ích", "—", "FR-46")
        ]),
        ("Bộ phận: Quản trị Hệ thống, An toàn & Thông báo", "QTHT", [
            ("1", "Gửi thông báo hệ thống tự động", "Kết Xuất", "Tạo thông báo khi có Match mới, có lịch hẹn", "—", "FR-33"),
            ("2", "Xem & Quản lý trung tâm thông báo", "Tra Cứu", "Xem lịch sử thông báo, đánh dấu đã đọc", "—", "FR-50"),
            ("3", "Cấu hình tùy chọn nhận thông báo", "Lưu Trữ", "Bật/tắt thông báo đẩy, email nhắc lịch", "—", "FR-51"),
            ("4", "Chặn người dùng (Block)", "Lưu Trữ", "Cắt đứt liên hệ 2 chiều, hủy mọi yêu cầu đang chờ", "—", "FR-34"),
            ("5", "Báo cáo người dùng vi phạm", "Lưu Trữ", "Gửi đơn khiếu nại kèm bằng chứng sai phạm", "—", "FR-35"),
            ("6", "Xem danh sách chặn & Bỏ chặn", "Tra Cứu", "Quản lý danh sách tài khoản đã đưa vào blacklist", "—", "FR-52"),
            ("7", "Báo cáo bài đăng phòng vi phạm", "Lưu Trữ", "Báo cáo tin đăng lừa đảo, phòng ảo, cọc ảo", "—", "FR-53"),
            ("8", "Quản lý & Khóa tài khoản người dùng", "Lưu Trữ", "Quyền Admin: Xem, khóa/mở khóa tài khoản", "—", "FR-36"),
            ("9", "Xử lý đơn báo cáo vi phạm", "Lưu Trữ", "Quyền Admin: Tiếp nhận và xử lý khiếu nại", "—", "FR-37"),
            ("10", "Kiểm duyệt & Ẩn bài đăng vi phạm", "Lưu Trữ", "Quyền Admin: Ẩn tin vi phạm khỏi ứng dụng", "—", "FR-54")
        ])
    ]

    col_widths_fr = [0.4, 1.8, 0.9, 2.0, 0.9, 0.5]
    for dept_title, dept_code, fr_list in departments:
        add_h3(f"{dept_title} (Mã số: {dept_code})")
        t_dept = doc.add_table(rows=1, cols=6)
        t_dept.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_grid_borders(t_dept)
        format_table_header(t_dept.rows[0], col_widths_fr, ["STT", "Công Việc", "Loại Công Việc", "Quy Định / Công Thức Liên Quan", "Biểu Mẫu", "Mã"])
        for idx, row_val in enumerate(fr_list):
            r_elem = t_dept.add_row()
            format_table_row(r_elem, col_widths_fr, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER])
        add_p("") # spacing

    add_h2("2.3. Các biểu mẫu nghiệp vụ mẫu (Mockup Templates)")
    add_p("Theo quy chuẩn kỹ thuật tại Mau_XDYC.docx, dưới đây là các biểu mẫu nghiệp vụ chính được sử dụng để thu thập và xử lý thông tin trong toàn bộ hệ thống:")

    # Form Mockups Box
    forms = [
        ("QLTK_BM1: BIỂU MẪU ĐĂNG KÝ TÀI KHOẢN VÀ HỒ SƠ NGƯỜI DÙNG", [
            "Họ và tên: _____________________________________   Giới tính: [ ] Nam   [ ] Nữ",
            "Email đăng ký: __________________________________   Số điện thoại: ____________________",
            "Mật khẩu: ______________________________________   Xác nhận mật khẩu: ________________",
            "Trường ĐH / Nghề nghiệp: ________________________   Khu vực mong muốn: _______________",
            "Ảnh đại diện (URL/File): [ Chọn tệp... ]"
        ]),
        ("QLTC_BM1: PHIẾU KHẢO SÁT TIÊU CHÍ VÀ THÓI QUEN LỐI SỐNG (5 CHIỀU)", [
            "1. Ngân sách thuê trọ tối đa: _____________________ VNĐ/tháng",
            "2. Thói quen giờ giấc sinh hoạt:",
            "   - Giờ ngủ: [ ] Trước 23h (Ngủ sớm)   [ ] 23h - 1h (Bình thường)   [ ] Sau 1h sáng (Cú đêm)",
            "   - Giờ thức dậy: [ ] Trước 6h30   [ ] 6h30 - 8h   [ ] Sau 8h sáng",
            "3. Mức độ sạch sẽ, ngăn nắp (Thang điểm 1 - 5): [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]",
            "4. Thói quen hút thuốc lá: [ ] Không hút thuốc   [ ] Có hút thuốc",
            "5. Thú cưng (Chó/Mèo): [ ] Không nuôi / Dị ứng lông   [ ] Yêu thích / Có nuôi thú cưng",
            "6. Giới thiệu bản thân & Yêu cầu thêm: ____________________________________________________"
        ]),
        ("QLBD_BM1: PHIẾU ĐĂNG BÀI TÌM BẠN CÙNG THUÊ PHÒNG TRỌ", [
            "Tiêu đề bài đăng: ____________________________________________________________________",
            "Địa chỉ phòng trọ: Số nhà ____, Đường ________________, Phường __________, Quận ________",
            "Giá thuê phòng: ________________ VNĐ/tháng    Tiền điện: __________   Tiền nước: ________",
            "Diện tích: ______ m2    Số lượng người tối đa: _____    Số chỗ còn cần tìm: _____",
            "Tiện ích phòng: [ ] Máy lạnh   [ ] Gác lửng   [ ] Tủ lạnh   [ ] Máy giặt   [ ] Giờ tự do",
            "Mô tả chi tiết phòng trọ: ______________________________________________________________"
        ]),
        ("QLKN_BM1: PHIẾU YÊU CẦU GHÉP ĐÔI VÀ THIẾT LẬP KẾT NỐI (DOUBLE OPT-IN)", [
            "Mã yêu cầu: MR-__________    Ngày gửi: ____/____/2026    Thời hạn phản hồi: 7 ngày",
            "Người gửi (A): ___________________________    Người nhận (B): ___________________________",
            "Điểm số Matching Score: _______ %",
            "Lời nhắn gửi kèm: _____________________________________________________________________",
            "Trạng thái xác nhận: [ ] PENDING (Đang chờ)   [ ] ACCEPTED (Chấp nhận)   [ ] REJECTED (Từ chối)",
            "Quyền chia sẻ thông tin khi ACCEPTED: [x] Số điện thoại   [x] Zalo cá nhân   [ ] Email"
        ]),
        ("QLLH_BM1: GIẤY HẸN XEM PHÒNG TRỌ THỰC TẾ", [
            "Mã lịch hẹn: LH-__________    Phòng trọ áp dụng: Bài đăng số ___________________________",
            "Người đề xuất lịch hẹn: ____________________    Người tiếp nhận: ________________________",
            "Thời gian hẹn gặp: Giờ: ____:____  Ngày: ____/____/2026",
            "Địa điểm hẹn gặp: _____________________________________________________________________",
            "Trạng thái: [ ] Đang chờ xác nhận   [ ] Đã xác nhận   [ ] Đã hủy   [ ] Đã hoàn thành"
        ])
    ]

    for f_title, f_lines in forms:
        add_h3(f_title)
        tf = doc.add_table(rows=1, cols=1)
        tf.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_box_borders(tf, color="2E75B6", sz="6", val="single")
        c = tf.cell(0, 0)
        c.width = Inches(6.5)
        set_cell_shading(c, "F2F4F7")
        set_cell_margins(c, top=100, bottom=100, left=150, right=150)
        for line in f_lines:
            p_box = c.add_paragraph()
            p_box.paragraph_format.space_before = Pt(2)
            p_box.paragraph_format.space_after = Pt(2)
            p_box.paragraph_format.line_spacing = 1.15
            r = p_box.add_run(line)
            r.font.name = 'Courier New' if "___" in line else 'Times New Roman'
            r.font.size = Pt(10)
        add_p("") # spacing

    add_h2("2.4. Danh sách yêu cầu phi chức năng (NFRs)")
    add_p("Hệ thống Roommate Matching Hub tuân thủ nghiêm ngặt các tiêu chuẩn chất lượng công nghiệp:")

    t_nfr = doc.add_table(rows=1, cols=5)
    t_nfr.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_nfr)
    col_w_nfr = [0.4, 1.8, 1.1, 2.5, 0.7]
    format_table_header(t_nfr.rows[0], col_w_nfr, ["STT", "Nội Dung Yêu Cầu", "Tiêu Chuẩn", "Mô Tả Kỹ Thuật Chi Tiết", "Ghi Chú"])
    
    nfr_data = [
        ("1", "Bảo mật tài khoản & dữ liệu", "Bảo mật (Security)", "Mật khẩu mã hóa BCrypt với cost factor = 10. API bảo vệ qua chuẩn JWT Bearer Token. Thông tin liên hệ SĐT/Email được ẩn danh 100% trước khi Double Opt-in thành công.", "Bắt buộc"),
        ("2", "Hiệu năng tính toán Matching", "Hiệu năng (Performance)", "Thời gian tính toán và trả về danh sách gợi ý bạn ở ghép tối đa dưới 1.5 giây cho tập dữ liệu 1,000 hồ sơ đồng thời.", "Bắt buộc"),
        ("3", "Tính khả dụng & Tiện dụng", "Tiện dụng (Usability)", "Giao diện tối ưu hóa cho màn hình điện thoại di động và Web. Người dùng hoàn thành bảng khảo sát 5 tiêu chí dưới 2 phút.", "Quan trọng"),
        ("4", "Độ tin cậy & Toàn vẹn dữ liệu", "Tin cậy (Reliability)", "Giao dịch xác nhận Double Opt-in, trừ số chỗ trống của phòng trọ phải đảm bảo tính ACID trong cơ sở dữ liệu MySQL, không xảy ra race-condition.", "Bắt buộc"),
        ("5", "Khả năng tương thích nền tảng", "Tương thích (Compatibility)", "Hệ thống hỗ trợ mượt mà trên các trình duyệt hiện đại (Chrome, Edge, Safari) và ứng dụng di động Android 10+ / iOS 15+.", "Quan trọng")
    ]
    for idx, row_val in enumerate(nfr_data):
        row = t_nfr.add_row()
        format_table_row(row, col_w_nfr, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER])

    doc.add_page_break()

    # ==========================================
    # PHẦN 3. DANH SÁCH TÁC NHÂN VÀ CHỨC NĂNG CỦA PHẦN MỀM
    # ==========================================
    add_h1("PHẦN 3. DANH SÁCH TÁC NHÂN VÀ CHỨC NĂNG CỦA PHẦN MỀM")
    
    add_h2("3.1. Nhận diện các tác nhân hệ thống")
    add_p("Hệ thống xác định 4 tác nhân chính tham gia vào quy trình hoạt động:")
    add_p("1. Người dùng (User): Sinh viên, người đi làm có nhu cầu tìm bạn ở ghép, tìm phòng trọ.")
    add_p("2. Người dùng có phòng (Room Host): Vai trò chuyên biệt của Người dùng khi họ đang thuê một phòng trọ và cần tìm thêm bạn ở ghép vào phòng của mình.")
    add_p("3. Quản trị viên (Admin): Người quản trị vận hành hệ thống, chịu trách nhiệm duyệt tin phòng và xử lý các vi phạm.")
    add_p("4. Hệ thống (System / Background Engine): Tác nhân nền tự động tính điểm tương thích Matching Score, tự động gửi thông báo và tự động hết hạn yêu cầu ghép đôi sau 7 ngày.")

    add_h2("3.2. Bảng 3.1: Nhận diện tác nhân và chức năng phần mềm")
    add_p("Bảng ánh xạ trách nhiệm giữa các tác nhân và danh mục chức năng tương ứng:")

    t_actor_fn = doc.add_table(rows=1, cols=2)
    t_actor_fn.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_actor_fn)
    col_w_afn = [2.0, 4.5]
    format_table_header(t_actor_fn.rows[0], col_w_afn, ["Tác nhân (Actor)", "Danh mục Chức năng Thực hiện"])

    actor_fn_data = [
        ("Người dùng (User)", "Đăng ký, Đăng nhập, Đăng xuất, Đặt lại mật khẩu, Đổi mật khẩu, Xác minh email; Cập nhật hồ sơ, Xem hồ sơ, Cập nhật trạng thái tìm kiếm; Khai báo tiêu chí cứng, Khai báo tiêu chí mềm, Cập nhật tiêu chí, Đặt ưu tiên tiêu chí; Tìm kiếm bộ lọc, Xem danh sách gợi ý, So sánh hồ sơ, Lưu yêu thích; Gửi Match Request, Hủy Match Request, Chấp nhận Match Request, Từ chối Match Request; Xem danh sách kết nối, Hủy kết nối, Thiết lập quyền chia sẻ thông tin liên lạc; Đề xuất lịch xem phòng, Quản lý phản hồi lịch hẹn; Xác nhận kết quả ở ghép; Chặn người dùng, Báo cáo người dùng, Báo cáo bài đăng phòng; Quản lý trung tâm thông báo."),
        ("Người dùng có phòng (Room Host)", "Toàn bộ quyền hạn của Người dùng; Đăng bài tìm bạn ở ghép, Chỉnh sửa bài đăng phòng, Đóng bài đăng phòng, Cập nhật số lượng chỗ trống còn lại; Tiếp nhận và xử lý lịch hẹn xem phòng trọ."),
        ("Quản trị viên (Admin)", "Đăng nhập trang quản trị; Quản lý danh sách người dùng, Khóa / Mở khóa tài khoản vi phạm; Tiếp nhận và xử lý đơn khiếu nại báo cáo vi phạm; Kiểm duyệt tin đăng phòng, Ẩn các bài đăng phòng ảo/lừa đảo."),
        ("Hệ thống tự động (System)", "Tính toán Matching Score theo công thức đa tiêu chí; Xác nhận kích hoạt Double Opt-in; Mở kết nối liên lạc; Tự động chuyển trạng thái Expired cho Match Request sau 7 ngày; Gửi thông báo đẩy và email nhắc lịch hẹn xem phòng trước 24 giờ.")
    ]
    for idx, row_val in enumerate(actor_fn_data):
        row = t_actor_fn.add_row()
        format_table_row(row, col_w_afn, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.JUSTIFY])

    add_h2("3.3. Bảng 3.2: Chi tiết các tác nhân (Vai trò & Mục đích)")
    
    t_act_detail = doc.add_table(rows=1, cols=4)
    t_act_detail.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_act_detail)
    col_w_ad = [1.5, 1.6, 2.4, 1.0]
    format_table_header(t_act_detail.rows[0], col_w_ad, ["Tác nhân", "Vai trò thực tế", "Mục đích sử dụng", "Quyền hạn"])

    act_detail_data = [
        ("Người dùng (User)", "Sinh viên / người đi làm tìm bạn ở ghép", "Tìm kiếm được bạn cùng phòng có lối sống tương thích, tiết kiệm chi phí thuê trọ", "Người dùng tiêu chuẩn"),
        ("Người dùng có phòng", "Chủ phòng / Người đại diện phòng trọ", "Tìm kiếm thêm người lấp đầy chỗ trống trong phòng để giảm gánh nặng tiền trọ", "Quản lý bài đăng phòng cá nhân"),
        ("Quản trị viên (Admin)", "Người vận hành hệ thống", "Duy trì an toàn, lành mạnh cho nền tảng; loại bỏ lừa đảo và tài khoản quấy rối", "Toàn quyền quản trị"),
        ("Hệ thống (System)", "Động cơ xử lý tự động nền", "Đảm bảo tính khách quan của điểm số Matching, tự động hóa quy trình kết nối và cảnh báo", "Hệ thống nội bộ")
    ]
    for idx, row_val in enumerate(act_detail_data):
        row = t_act_detail.add_row()
        format_table_row(row, col_w_ad, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER])

    add_h2("3.4. Bảng 3.3: Danh sách các chức năng và mô tả chi tiết")
    add_p("Tổng hợp đầy đủ 54 chức năng của hệ thống Roommate Matching Hub:")

    t_all_fn = doc.add_table(rows=1, cols=3)
    t_all_fn.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_all_fn)
    col_w_afn_all = [0.6, 1.8, 4.1]
    format_table_header(t_all_fn.rows[0], col_w_afn_all, ["Mã", "Tên Chức Năng", "Mô Tả Chi Tiết Hành Vi Hệ Thống"])

    # 54 FRs descriptions
    all_54_frs = [
        ("FR-01", "Đăng ký tài khoản", "Người dùng tạo tài khoản mới bằng email và mật khẩu. Mật khẩu được mã hóa an toàn bằng thuật toán BCrypt."),
        ("FR-02", "Đăng nhập tài khoản", "Xác thực email và mật khẩu, hệ thống trả về mã định danh JWT Token cho các phiên làm việc."),
        ("FR-03", "Đăng xuất tài khoản", "Hủy bỏ token đăng nhập hiện tại và giải phóng phiên làm việc."),
        ("FR-04", "Đặt lại mật khẩu", "Khôi phục mật khẩu khi người dùng quên thông qua mã OTP bảo mật gửi đến email đăng ký."),
        ("FR-05", "Cập nhật hồ sơ cá nhân", "Chỉnh sửa thông tin hồ sơ: Họ và tên, ảnh đại diện, số điện thoại, giới tính, tiểu sử cá nhân."),
        ("FR-06", "Xem hồ sơ cá nhân", "Hiển thị toàn bộ thông tin tài khoản và kết quả khảo sát lối sống hiện hành."),
        ("FR-07", "Khai báo tiêu chí cứng", "Khai báo các điều kiện tiên quyết: Giới tính mong muốn của bạn cùng phòng, khu vực quận, mức ngân sách tối đa."),
        ("FR-08", "Khai báo tiêu chí mềm", "Khai báo 5 tiêu chí thói quen: Giờ ngủ, giờ dậy, thang đo độ sạch sẽ (1-5), thói quen hút thuốc, nuôi thú cưng."),
        ("FR-09", "Cập nhật tiêu chí khảo sát", "Cho phép người dùng cập nhật lại các thông số tiêu chí cứng và mềm khi thói quen thay đổi."),
        ("FR-10", "Tìm kiếm theo bộ lọc", "Tìm kiếm danh sách ứng viên theo các bộ lọc kết hợp: Quận mục tiêu, khoảng giá phòng, giới tính."),
        ("FR-11", "Xem danh sách gợi ý", "Hệ thống hiển thị danh sách các bạn cùng phòng tiềm năng được sắp xếp theo % tương thích giảm dần."),
        ("FR-12", "Tính Matching Score", "Động cơ nền tự động tính toán điểm số tương thích giữa 2 hồ sơ dựa trên công thức trọng số đa tiêu chí."),
        ("FR-13", "Xem chi tiết hồ sơ ứng viên", "Xem chi tiết hồ sơ phong cách sống của đối phương dưới chế độ ẩn danh (chưa hiện SĐT/Zalo)."),
        ("FR-14", "Gửi yêu cầu ghép đôi", "Người dùng gửi Match Request đến một ứng viên kèm lời nhắn giới thiệu bản thân."),
        ("FR-15", "Chấp nhận yêu cầu ghép đôi", "Người nhận đồng ý kết nối; hệ thống kích hoạt cơ chế Double Opt-in và chuyển sang kết nối Active."),
        ("FR-16", "Từ chối yêu cầu ghép đôi", "Người nhận từ chối Match Request; chuyển trạng thái yêu cầu sang REJECTED."),
        ("FR-17", "Xác nhận Double Opt-in", "Hệ thống xác nhận tính đồng thuận 2 chiều, chính thức thiết lập kết nối an toàn giữa hai bên."),
        ("FR-18", "Mở kết nối liên lạc", "Hệ thống mở khóa hiển thị thông tin liên lạc (SĐT/Zalo) theo quyền chia sẻ mà mỗi bên đã thiết lập."),
        ("FR-19", "Xem danh sách kết nối", "Hiển thị danh sách các bạn cùng phòng đã ghép đôi thành công kèm thông tin liên lạc."),
        ("FR-20", "Đăng bài tìm người ở ghép", "Người có phòng đăng bài gồm tiêu đề, địa chỉ phòng, giá thuê, tiện ích, số lượng cần tìm và hình ảnh."),
        ("FR-21", "Xem danh sách bài đăng phòng", "Hiển thị các bài đăng tìm người ở ghép đang công khai và còn chỗ trống trên hệ thống."),
        ("FR-22", "Xác minh email", "Người dùng nhập mã xác thực gửi về email để kích hoạt đầy đủ các tính năng tài khoản."),
        ("FR-23", "Thay đổi mật khẩu", "Người dùng đổi mật khẩu chủ động bằng cách xác thực lại mật khẩu hiện tại."),
        ("FR-24", "Cập nhật trạng thái tìm trọ", "Bật/tắt trạng thái 'Đang tìm bạn ở ghép'. Khi tắt, hồ sơ sẽ tự động ẩn khỏi danh sách gợi ý."),
        ("FR-25", "Thiết lập mức ưu tiên tiêu chí", "Gán trọng số quan trọng (Bắt buộc / Rất quan trọng / Bình thường) cho từng tiêu chí mềm."),
        ("FR-26", "Sắp xếp danh sách kết quả", "Sắp xếp danh sách bạn trọ theo: Điểm tương thích giảm dần, Mức giá tăng dần, Độ sạch sẽ."),
        ("FR-27", "Xem lý do tương thích", "Phân tích trực quan các tiêu chí trùng khớp hoàn toàn (màu xanh) và tiêu chí có độ lệch (màu vàng/đỏ)."),
        ("FR-28", "Hủy yêu cầu ghép đôi", "Người gửi chủ động rút lại Match Request đã gửi khi đối phương chưa kịp phản hồi (Pending)."),
        ("FR-29", "Hủy kết nối bạn trọ", "Chấm dứt kết nối đã tạo; hệ thống lập tức thu hồi quyền truy cập số điện thoại và hủy lịch hẹn chưa diễn ra."),
        ("FR-30", "Chỉnh sửa bài đăng phòng", "Chủ phòng chỉnh sửa thông tin giá, tiện ích, mô tả chi tiết của bài đăng phòng trọ."),
        ("FR-31", "Đóng bài đăng phòng", "Chủ phòng chuyển trạng thái bài đăng sang CLOSED khi đã tìm đủ số lượng người ở ghép."),
        ("FR-32", "Xem chi tiết bài đăng phòng", "Hiển thị đầy đủ hình ảnh, giá phòng, tiền dịch vụ điện nước, địa chỉ và thông tin chủ bài đăng."),
        ("FR-33", "Gửi thông báo hệ thống", "Tự động gửi thông báo đẩy và thông báo ứng dụng khi có yêu cầu ghép đôi mới, có phản hồi hoặc lịch hẹn."),
        ("FR-34", "Chặn người dùng (Block)", "Chặn liên lạc 2 chiều vĩnh viễn; ẩn hồ sơ khỏi kết quả tìm kiếm của nhau và hủy toàn bộ yêu cầu đang chờ."),
        ("FR-35", "Báo cáo người dùng", "Gửi khiếu nại báo cáo tài khoản có hành vi quấy rối, thông tin sai sự thật đến ban quản trị."),
        ("FR-36", "Quản lý tài khoản người dùng", "Quản trị viên xem danh sách thành viên, thực hiện khóa (LOCK) hoặc mở khóa tài khoản vi phạm."),
        ("FR-37", "Xử lý báo cáo vi phạm", "Quản trị viên tiếp nhận đơn báo cáo, xem xét bằng chứng và đưa ra quyết định xử lý phù hợp."),
        ("FR-38", "Nhắn tin trong kết nối", "(Optional) Kênh chat nhắn tin văn bản nội bộ giữa 2 người dùng sau khi đã Double Opt-in thành công."),
        ("FR-39", "Quản lý danh sách yêu thích", "Người dùng lưu trữ (Bookmark) danh sách các ứng viên hoặc bài đăng phòng ưng ý để xem lại nhanh."),
        ("FR-40", "So sánh hồ sơ ứng viên", "Đặt 2 đến 3 hồ sơ ứng viên lên bảng so sánh song song đối đầu về ngân sách, giờ giấc, độ sạch sẽ."),
        ("FR-41", "Lưu bộ lọc & theo dõi gợi ý", "Lưu cấu hình bộ lọc tìm kiếm yêu thích và nhận thông báo khi có người mới đăng ký phù hợp."),
        ("FR-42", "Khai báo thời gian vào ở", "Khai báo khoảng ngày dự kiến có thể dọn vào ở và thời hạn thuê trọ tối thiểu mong muốn."),
        ("FR-43", "Xem & lọc yêu cầu gửi/nhận", "Giao diện quản lý phân tách 2 tab: Yêu cầu đã gửi và Yêu cầu đã nhận, có bộ lọc theo trạng thái."),
        ("FR-44", "Tự động hết hạn Match Request", "Match Request tự động chuyển sang trạng thái EXPIRED sau 7 ngày nếu người nhận không phản hồi."),
        ("FR-45", "Thiết lập quyền chia sẻ liên lạc", "Chủ động chọn trường thông tin cá nhân (SĐT, Zalo, Email) cho phép đối phương nhìn thấy sau khi match."),
        ("FR-46", "Tìm kiếm phòng theo bộ lọc", "Lọc bài đăng phòng theo: Khu vực quận, khoảng giá, số chỗ còn trống, tiện ích máy lạnh/máy giặt."),
        ("FR-47", "Đề xuất lịch hẹn xem phòng", "Gửi lời hẹn gặp mặt trực tiếp tại phòng trọ gồm thời gian, thời lượng và địa điểm hẹn gặp."),
        ("FR-48", "Phản hồi & Quản lý lịch hẹn", "Chủ phòng chấp nhận, từ chối, đề xuất lại giờ hẹn hoặc hủy lịch hẹn; nhận nhắc lịch trước 24 giờ."),
        ("FR-49", "Xác nhận kết quả ở ghép", "Hai bên cùng xác nhận đã đồng ý ở ghép thành công; hệ thống tự động trừ số chỗ trống của bài đăng."),
        ("FR-50", "Trung tâm thông báo", "Màn hình trung tâm quản lý lịch sử thông báo, đánh dấu đã đọc và điều hướng đến sự kiện liên quan."),
        ("FR-51", "Cấu hình nhận thông báo", "Cho phép bật/tắt nhận thông báo đẩy qua ứng dụng hoặc qua email theo từng nhóm sự kiện."),
        ("FR-52", "Xem danh sách chặn & Bỏ chặn", "Quản lý danh sách các tài khoản đang bị chặn và hỗ trợ thao tác bỏ chặn khi cần thiết."),
        ("FR-53", "Báo cáo bài đăng phòng vi phạm", "Báo cáo tin đăng phòng trọ giả mạo, phòng lừa đảo cọc, địa chỉ không có thật kèm hình ảnh bằng chứng."),
        ("FR-54", "Kiểm duyệt & Ẩn bài đăng vi phạm", "Quản trị viên xem xét báo cáo bài đăng và thực hiện ẩn (HIDE) tin đăng phòng vi phạm khỏi ứng dụng.")
    ]

    for idx, row_val in enumerate(all_54_frs):
        row = t_all_fn.add_row()
        format_table_row(row, col_w_afn_all, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.JUSTIFY], font_size=10)

    doc.add_page_break()

    # ==========================================
    # PHẦN 4. (CÁC) LƯỢC ĐỒ CHỨC NĂNG & ĐẶC TẢ USE CASE
    # ==========================================
    add_h1("PHẦN 4. (CÁC) LƯỢC ĐỒ CHỨC NĂNG & ĐẶC TẢ USE CASE")
    
    add_h2("4.1. Danh mục 6 Lược đồ Use Case phân hệ")
    add_p("Để mô hình hóa hệ thống rõ ràng trên công cụ Enterprise Architect / StarUML và tránh việc nhồi nhét quá nhiều Use Case vào một sơ đồ duy nhất, hệ thống Roommate Matching Hub được phân chia thành 6 Lược đồ chức năng chuyên biệt:")
    add_p("1. Lược đồ 1: Quản lý Tài khoản & Hồ sơ cá nhân (Account & Profile Management)")
    add_p("2. Lược đồ 2: Khảo sát Tiêu chí, Tìm kiếm & So sánh (Criteria, Search & Comparison)")
    add_p("3. Lược đồ 3: Thuật toán Matching & Ghép đôi Double Opt-in (Matching & Connection Lifecycle)")
    add_p("4. Lược đồ 4: Quản lý Kết nối & Lịch hẹn xem phòng (Connected Roommates & Viewing Appointments)")
    add_p("5. Lược đồ 5: Quản lý Bài đăng phòng trọ (Room Post Management)")
    add_p("6. Lược đồ 6: Thông báo, An toàn & Quản trị hệ thống (Notifications, Safety & Administration)")

    add_h2("4.2. Danh sách quan hệ <<include>> và <<extend>>")
    add_p("Tuân thủ phương pháp luận UML chuẩn mực, các mối quan hệ phụ thuộc giữa các Use Case được xác định như sau:")

    add_h3("a) Danh mục quan hệ phụ thuộc bắt buộc (<<include>>)")
    t_inc = doc.add_table(rows=1, cols=3)
    t_inc.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_inc)
    col_w_ie = [2.2, 2.0, 2.3]
    format_table_header(t_inc.rows[0], col_w_ie, ["Use Case Cơ Sở (Base)", "Use Case Được Bao Hàm (Included)", "Giải Thích Lý Do Kỹ Thuật"])

    inc_data = [
        ("Đăng ký tài khoản (UC-01)", "Xác minh email (UC-22)", "Xác minh email là bước bắt buộc để kích hoạt tài khoản hợp lệ."),
        ("Xem danh sách gợi ý (UC-11)", "Tính Matching Score (UC-12)", "Để hiển thị danh sách xếp hạng, hệ thống bắt buộc phải tính điểm tương thích trước."),
        ("Chấp nhận yêu cầu ghép đôi (UC-15)", "Xác nhận Double Opt-in (UC-17)", "Khi bên nhận chấp thuận, hệ thống bắt buộc xác nhận sự đồng thuận 2 chiều."),
        ("Xác nhận Double Opt-in (UC-17)", "Mở kết nối liên lạc (UC-18)", "Ngay khi Double Opt-in thành công, hệ thống luôn tự động tạo kết nối liên lạc."),
        ("Gửi yêu cầu ghép đôi (UC-14)", "Gửi thông báo hệ thống (UC-33)", "Mỗi khi phát sinh Match Request, hệ thống bắt buộc gửi thông báo đến người nhận."),
        ("Xác nhận Double Opt-in (UC-17)", "Gửi thông báo hệ thống (UC-33)", "Cả hai bên bắt buộc nhận được thông báo chúc mừng ghép đôi thành công.")
    ]
    for idx, row_val in enumerate(inc_data):
        row = t_inc.add_row()
        format_table_row(row, col_w_ie, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])

    add_h3("b) Danh mục quan hệ mở rộng theo điều kiện (<<extend>>)")
    t_ext = doc.add_table(rows=1, cols=3)
    t_ext.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_ext)
    format_table_header(t_ext.rows[0], col_w_ie, ["Use Case Cơ Sở (Base)", "Use Case Mở Rộng (Extension)", "Điểm Mở Rộng & Điều Kiện Kích Hoạt"])

    ext_data = [
        ("Xem chi tiết hồ sơ ứng viên (UC-13)", "Xem lý do tương thích (UC-27)", "Kích hoạt khi người dùng muốn xem phân tích chi tiết tiêu chí trùng khớp."),
        ("Xem chi tiết hồ sơ ứng viên (UC-13)", "Chặn người dùng (UC-34)", "Kích hoạt khi phát hiện hồ sơ có dấu hiệu quấy rối hoặc không phù hợp."),
        ("Xem chi tiết hồ sơ ứng viên (UC-13)", "Báo cáo người dùng (UC-35)", "Kích hoạt khi phát hiện hành vi lừa đảo hoặc vi phạm quy tắc cộng đồng."),
        ("Xem danh sách gợi ý (UC-11)", "So sánh hồ sơ ứng viên (UC-40)", "Kích hoạt khi người dùng chọn cùng lúc 2 đến 3 bạn trọ để so sánh."),
        ("Gửi yêu cầu ghép đôi (UC-14)", "Hủy yêu cầu ghép đôi (UC-28)", "Kích hoạt khi yêu cầu vẫn còn ở trạng thái PENDING và người gửi muốn rút lại."),
        ("Xem danh sách kết nối (UC-19)", "Đề xuất lịch xem phòng (UC-47)", "Kích hoạt khi 2 bạn trọ đã match và một bên có phòng muốn hẹn gặp xem trọ."),
        ("Xem danh sách kết nối (UC-19)", "Hủy kết nối (UC-29)", "Kích hoạt khi hai bên không còn nhu cầu ở ghép chung với nhau."),
        ("Đăng bài tìm người ở ghép (UC-20)", "Đóng bài đăng phòng (UC-31)", "Kích hoạt khi bài đăng đã tìm đủ số lượng người ở ghép cần thiết.")
    ]
    for idx, row_val in enumerate(ext_data):
        row = t_ext.add_row()
        format_table_row(row, col_w_ie, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])

    add_h2("4.3. Bảng Ma trận truy vết yêu cầu (Traceability Matrix)")
    add_p("Ma trận đối chiếu giữa 54 Yêu cầu chức năng (FRs), Tác nhân và Lược đồ Use Case tương ứng:")

    t_mat = doc.add_table(rows=1, cols=4)
    t_mat.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_grid_borders(t_mat)
    col_w_m = [0.8, 2.5, 1.7, 1.5]
    format_table_header(t_mat.rows[0], col_w_m, ["Yêu Cầu (FR)", "Use Case Ánh Xạ", "Tác Nhân Chính", "Lược Đồ Phân Hệ"])

    matrix_rows = [
        ("FR-01", "UC-01: Đăng ký tài khoản", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-02", "UC-02: Đăng nhập", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-03", "UC-03: Đăng xuất", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-04", "UC-04: Đặt lại mật khẩu", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-05", "UC-05: Cập nhật hồ sơ", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-06", "UC-06: Xem hồ sơ", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-07", "UC-07: Khai báo tiêu chí cứng", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-08", "UC-08: Khai báo tiêu chí mềm", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-09", "UC-09: Cập nhật tiêu chí", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-10", "UC-10: Tìm kiếm theo bộ lọc", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-11", "UC-11: Xem danh sách gợi ý", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-12", "UC-12: Tính Matching Score", "Hệ thống (System)", "Lược đồ 3: Matching"),
        ("FR-13", "UC-13: Xem chi tiết hồ sơ", "Người dùng", "Lược đồ 3: Matching"),
        ("FR-14", "UC-14: Gửi yêu cầu ghép đôi", "Người dùng", "Lược đồ 3: Matching"),
        ("FR-15", "UC-15: Chấp nhận yêu cầu", "Người dùng", "Lược đồ 3: Matching"),
        ("FR-16", "UC-16: Từ chối yêu cầu", "Người dùng", "Lược đồ 3: Matching"),
        ("FR-17", "UC-17: Xác nhận Double Opt-in", "Hệ thống (System)", "Lược đồ 3: Matching"),
        ("FR-18", "UC-18: Mở kết nối liên lạc", "Hệ thống (System)", "Lược đồ 4: Kết nối"),
        ("FR-19", "UC-19: Xem danh sách kết nối", "Người dùng", "Lược đồ 4: Kết nối"),
        ("FR-20", "UC-20: Đăng bài tìm ở ghép", "Người dùng có phòng", "Lược đồ 5: Bài đăng"),
        ("FR-21", "UC-21: Xem danh sách bài đăng", "Người dùng", "Lược đồ 5: Bài đăng"),
        ("FR-22", "UC-22: Xác minh email", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-23", "UC-23: Thay đổi mật khẩu", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-24", "UC-24: Cập nhật trạng thái tìm trọ", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-25", "UC-25: Thiết lập ưu tiên tiêu chí", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-26", "UC-26: Sắp xếp danh sách kết quả", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-27", "UC-27: Xem lý do tương thích", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-28", "UC-28: Hủy yêu cầu ghép đôi", "Người dùng", "Lược đồ 3: Matching"),
        ("FR-29", "UC-29: Hủy kết nối", "Người dùng", "Lược đồ 4: Kết nối"),
        ("FR-30", "UC-30: Chỉnh sửa bài đăng", "Người dùng có phòng", "Lược đồ 5: Bài đăng"),
        ("FR-31", "UC-31: Đóng bài đăng phòng", "Người dùng có phòng", "Lược đồ 5: Bài đăng"),
        ("FR-32", "UC-32: Xem chi tiết bài đăng", "Người dùng", "Lược đồ 5: Bài đăng"),
        ("FR-33", "UC-33: Gửi thông báo hệ thống", "Hệ thống (System)", "Lược đồ 6: Thông báo"),
        ("FR-34", "UC-34: Chặn người dùng", "Người dùng", "Lược đồ 6: An toàn"),
        ("FR-35", "UC-35: Báo cáo người dùng", "Người dùng", "Lược đồ 6: An toàn"),
        ("FR-36", "UC-36: Quản lý tài khoản (Admin)", "Quản trị viên", "Lược đồ 6: Quản trị"),
        ("FR-37", "UC-37: Xử lý báo cáo vi phạm", "Quản trị viên", "Lược đồ 6: Quản trị"),
        ("FR-38", "UC-38: Nhắn tin trong kết nối", "Người dùng", "Lược đồ 4: Kết nối"),
        ("FR-39", "UC-39: Quản lý yêu thích", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-40", "UC-40: So sánh hồ sơ ứng viên", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-41", "UC-41: Lưu bộ lọc tìm kiếm", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-42", "UC-42: Khai báo ngày vào ở", "Người dùng", "Lược đồ 2: Tiêu chí"),
        ("FR-43", "UC-43: Xem/lọc yêu cầu gửi/nhận", "Người dùng", "Lược đồ 3: Matching"),
        ("FR-44", "UC-44: Tự động hết hạn yêu cầu", "Hệ thống (System)", "Lược đồ 3: Matching"),
        ("FR-45", "UC-45: Quyền chia sẻ liên lạc", "Người dùng", "Lược đồ 1: Tài khoản"),
        ("FR-46", "UC-46: Lọc bài đăng phòng", "Người dùng", "Lược đồ 5: Bài đăng"),
        ("FR-47", "UC-47: Đề xuất lịch xem phòng", "Người dùng", "Lược đồ 4: Lịch hẹn"),
        ("FR-48", "UC-48: Phản hồi lịch xem phòng", "Người dùng", "Lược đồ 4: Lịch hẹn"),
        ("FR-49", "UC-49: Xác nhận kết quả ở ghép", "Người dùng", "Lược đồ 4: Lịch hẹn"),
        ("FR-50", "UC-50: Trung tâm thông báo", "Người dùng", "Lược đồ 6: Thông báo"),
        ("FR-51", "UC-51: Cấu hình thông báo", "Người dùng", "Lược đồ 6: Thông báo"),
        ("FR-52", "UC-52: Xem danh sách chặn", "Người dùng", "Lược đồ 6: An toàn"),
        ("FR-53", "UC-53: Báo cáo bài đăng phòng", "Người dùng", "Lược đồ 5: Bài đăng"),
        ("FR-54", "UC-54: Kiểm duyệt bài đăng", "Quản trị viên", "Lược đồ 6: Quản trị")
    ]
    for idx, row_val in enumerate(matrix_rows):
        row = t_mat.add_row()
        format_table_row(row, col_w_m, row_val, is_even=(idx % 2 == 1), alignments=[WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT], font_size=10)

    add_h2("4.4. Quy tắc nghiệp vụ cốt lõi (Business Rules BR-01 -> BR-07)")
    add_p("Hệ thống xây dựng trên 7 quy tắc nghiệp vụ bất biến:")
    add_p("• BR-01 (Quy tắc Double Opt-in): Người A gửi yêu cầu, Người B chấp nhận yêu cầu khi còn hạn. Khi B chấp nhận, hệ thống tự động ghi nhận sự đồng thuận 2 chiều và mở kết nối. Không yêu cầu cả hai cùng tạo 2 yêu cầu độc lập gây trùng lặp dữ liệu.")
    add_p("• BR-02 (Điều kiện Tiêu chí cứng): Tiêu chí cứng (Giới tính bắt buộc, Ngân sách trần) là điều kiện lọc loại trừ. Nếu 2 ứng viên không thỏa mãn tiêu chí cứng của nhau thì điểm Matching tự động bằng 0% hoặc bị loại khỏi danh sách gợi ý.")
    add_p("• BR-03 (Bảo vệ quyền riêng tư): Trước khi Double Opt-in thành công, số điện thoại, email và địa chỉ nhà chính xác được che giấu 100% qua API.")
    add_p("• BR-04 (Thu hồi quyền khi Hủy/Chặn): Khi một bên thực hiện Hủy kết nối hoặc Chặn, quyền truy cập thông tin liên lạc lập tức bị vô hiệu hóa; toàn bộ lịch hẹn xem phòng chưa diễn ra tự động chuyển sang CANCELLED.")
    add_p("• BR-05 (Vòng đời yêu cầu ghép đôi): Yêu cầu có trạng thái Pending chỉ tồn tại tối đa 7 ngày. Hết 7 ngày hệ thống chuyển sang EXPIRED.")
    add_p("• BR-06 (Toàn vẹn số chỗ phòng trọ): Khi hai bên xác nhận ở ghép thành công (FR-49), số chỗ trống của bài đăng phòng trọ tự động giảm đi 1. Khi số chỗ còn lại = 0, bài đăng tự động chuyển sang CLOSED.")
    add_p("• BR-07 (Nhắc lịch hẹn): Lịch hẹn xem phòng đã xác nhận (Confirmed) sẽ kích hoạt thông báo nhắc nhở tự động trước thời điểm hẹn 24 giờ.")

    add_h2("4.5. Đặc tả chi tiết các Use Case cốt lõi")
    add_p("Dưới đây là bảng đặc tả chi tiết 7 Use Case cốt lõi nhất của hệ thống theo đúng biểu mẫu chuẩn quy định tại Mau_DacTaUsecase.docx:")

    # Detailed Use Case Tables Function
    def add_usecase_spec_table(uc_id, uc_name, actors, pre_cond, post_cond, main_steps, alt_steps, exc_steps):
        add_h3(f"Đặc tả {uc_id}: {uc_name}")
        tu = doc.add_table(rows=7, cols=2)
        tu.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_grid_borders(tu)
        col_w_u = [1.8, 4.7]
        
        headers = [
            ("Use Case ID & Tên chức năng", f"{uc_id} — {uc_name}"),
            ("Tác nhân tham gia", actors),
            ("Điều kiện tiên quyết (Pre-conditions)", pre_cond),
            ("Điều kiện thành công (Post-conditions)", post_cond),
            ("Luồng sự kiện chính (Main Flow)", main_steps),
            ("Luồng thay thế (Alternative Flow)", alt_steps),
            ("Luồng ngoại lệ (Exception Flows)", exc_steps)
        ]
        for idx, (label, content) in enumerate(headers):
            row = tu.rows[idx]
            cell_lbl = row.cells[0]
            cell_cnt = row.cells[1]
            cell_lbl.width = Inches(col_w_u[0])
            cell_cnt.width = Inches(col_w_u[1])
            set_cell_shading(cell_lbl, "EAEEF3")
            set_cell_margins(cell_lbl, top=80, bottom=80, left=100, right=100)
            set_cell_margins(cell_cnt, top=80, bottom=80, left=100, right=100)
            
            p_lbl = cell_lbl.paragraphs[0]
            p_lbl.alignment = WD_ALIGN_PARAGRAPH.LEFT
            r = p_lbl.add_run(label)
            r.font.name = 'Times New Roman'
            r.font.size = Pt(10.5)
            r.font.bold = True
            
            p_cnt = cell_cnt.paragraphs[0]
            p_cnt.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p_cnt.paragraph_format.line_spacing = 1.15
            r2 = p_cnt.add_run(content)
            r2.font.name = 'Times New Roman'
            r2.font.size = Pt(10.5)

        add_p("") # spacing

    # UC-01
    add_usecase_spec_table(
        "UC-01", "Đăng ký tài khoản người dùng",
        "Người dùng (User)",
        "Người dùng đã cài đặt ứng dụng hoặc truy cập trang chủ hệ thống.",
        "Tài khoản mới được tạo trong CSDL với mật khẩu mã hóa BCrypt; mã OTP xác thực được gửi tới email.",
        "1. Người dùng chọn chức năng 'Đăng ký tài khoản'.\n2. Hệ thống hiển thị form nhập: Họ tên, Email, Mật khẩu, Xác nhận mật khẩu.\n3. Người dùng điền đầy đủ thông tin và nhấn 'Đăng ký'.\n4. Hệ thống kiểm tra tính hợp lệ của dữ liệu.\n5. Hệ thống lưu tài khoản vào CSDL với trạng thái 'Chờ xác thực' và gửi mã OTP gồm 6 chữ số qua email.\n6. Người dùng nhập mã OTP xác thực.\n7. Hệ thống kích hoạt tài khoản thành công và chuyển hướng đến màn hình Khảo sát tiêu chí.",
        "Không có.",
        "4a. Email đã tồn tại trong hệ thống: Hệ thống báo đỏ ô email kèm thông báo 'Email đã được đăng ký'.\n4b. Mật khẩu dưới 6 ký tự hoặc không khớp: Báo lỗi 'Mật khẩu phải có tối thiểu 6 ký tự và trùng khớp'.\n6a. Nhập sai OTP: Thông báo 'Mã OTP không chính xác, vui lòng thử lại'.\n6b. OTP quá hạn (sau 5 phút): Hệ thống hiển thị 'Mã OTP đã hết hạn', cho phép bấm 'Gửi lại mã'."
    )

    # UC-07/08
    add_usecase_spec_table(
        "UC-07/08", "Khảo sát tiêu chí phong cách sống",
        "Người dùng (User)",
        "Người dùng đã đăng nhập thành công vào tài khoản.",
        "Dữ liệu tiêu chí cứng và mềm được lưu vào bảng user_preferences; hệ thống sẵn sàng tính toán Matching.",
        "1. Người dùng mở màn hình 'Khảo sát lối sống' (QLTC_BM1).\n2. Người dùng nhập tiêu chí cứng: Giới tính mong muốn, Ngân sách thuê tối đa, Khu vực quận mong muốn.\n3. Người dùng chọn tiêu chí mềm: Thói quen giờ ngủ, Giờ dậy, Đánh giá độ sạch sẽ (1-5), Tình trạng hút thuốc lá, Thú cưng.\n4. Người dùng nhập phần mô tả bản thân (tiểu sử ngắn).\n5. Người dùng nhấn nút 'Lưu khảo sát'.\n6. Hệ thống kiểm tra dữ liệu, lưu thông tin vào cơ sở dữ liệu và thông báo 'Cập nhật tiêu chí thành công'.\n7. Hệ thống tự động kích hoạt tiến trình tính toán lại Matching Score.",
        "3a. Người dùng có thể bỏ qua phần mô tả bản thân; hệ thống vẫn lưu các tiêu chí trắc nghiệm.",
        "2a. Ngân sách nhập vào là số âm hoặc bằng 0: Hệ thống báo lỗi 'Ngân sách phải lớn hơn 500,000 VNĐ'.\n2b. Bỏ trống khu vực quận: Hệ thống yêu cầu 'Vui lòng chọn ít nhất một khu vực mong muốn'."
    )

    # UC-12
    add_usecase_spec_table(
        "UC-12", "Tính Matching Score và gợi ý bạn ở ghép",
        "Hệ thống (System), Người dùng",
        "Người dùng đã hoàn thành khảo sát tiêu chí và bật trạng thái 'Đang tìm bạn trọ'.",
        "Danh sách bạn cùng phòng phù hợp được kết xuất với tỷ lệ % tương thích sắp xếp từ cao xuống thấp.",
        "1. Người dùng chọn tab 'Khám phá / Gợi ý bạn trọ'.\n2. Hệ thống truy vấn CSDL, quét các hồ sơ đang ở trạng thái tìm kiếm.\n3. Hệ thống áp dụng bộ lọc Tiêu chí cứng (Giới tính, Ngân sách trần, Quận).\n4. Với các ứng viên vượt qua lọc cứng, hệ thống tính điểm tương thích cho từng tiêu chí mềm theo trọng số: Điểm = ∑(wi * Si).\n5. Hệ thống chuẩn hóa điểm số về thang % (0% đến 100%).\n6. Hệ thống hiển thị danh sách các ứng viên có điểm từ cao xuống thấp kèm nhãn tương thích (Ví dụ: 95% - Rất hòa hợp).",
        "6a. Người dùng chọn đổi tiêu chí sắp xếp: Hệ thống sắp xếp lại theo giá thuê tăng dần hoặc theo độ sạch sẽ.",
        "3a. Không có ứng viên nào thỏa mãn tiêu chí cứng: Hệ thống hiển thị màn hình rỗng kèm gợi ý 'Mở rộng khu vực hoặc điều chỉnh ngân sách để tìm được nhiều bạn trọ hơn'."
    )

    # UC-14/15/17
    add_usecase_spec_table(
        "UC-14/15/17", "Gửi, chấp nhận ghép đôi và xác nhận Double Opt-in",
        "Người dùng gửi (A), Người dùng nhận (B), Hệ thống (System)",
        "Cả A và B đều có tài khoản hợp lệ, chưa từng chặn nhau, chưa có kết nối trước đó.",
        "Một Match Request chuyển trạng thái sang ACCEPTED, hệ thống tạo bản ghi Connection Active và mở kênh liên lạc.",
        "1. Người dùng A xem hồ sơ ẩn danh của B và nhấn 'Gửi yêu cầu ghép đôi'.\n2. A nhập lời nhắn ngắn và nhấn 'Xác nhận gửi'.\n3. Hệ thống tạo Match Request ở trạng thái PENDING với hạn phản hồi 7 ngày và gửi thông báo đến B.\n4. Người dùng B mở danh sách 'Yêu cầu đã nhận', xem hồ sơ của A và nhấn 'Chấp nhận'.\n5. Hệ thống kích hoạt quy tắc Double Opt-in (BR-01): Chuyển trạng thái yêu cầu sang ACCEPTED.\n6. Hệ thống tự động tạo bản ghi Kết nối (Connection) Active giữa A và B.\n7. Hệ thống mở thông tin liên lạc (SĐT/Zalo) theo quyền chia sẻ FR-45 và gửi thông báo chúc mừng tới cả hai.",
        "4a. B nhấn 'Từ chối': Yêu cầu chuyển trạng thái REJECTED; A nhận thông báo yêu cầu không thành công.\n1a. A chủ động nhấn 'Hủy yêu cầu' khi B chưa phản hồi: Yêu cầu chuyển sang CANCELLED.",
        "1a. A đã gửi yêu cầu cho B trước đó và đang Pending: Hệ thống chặn gửi lặp và thông báo 'Bạn đã gửi yêu cầu cho người này rồi'.\n4b. B chấp nhận khi yêu cầu đã quá 7 ngày: Hệ thống báo lỗi 'Yêu cầu ghép đôi đã hết hạn'."
    )

    # UC-20
    add_usecase_spec_table(
        "UC-20", "Đăng bài tìm bạn cùng thuê phòng trọ",
        "Người dùng có phòng (Room Host)",
        "Người dùng đã đăng nhập và đã xác minh số điện thoại.",
        "Bài đăng phòng trọ mới được tạo thành công trên hệ thống ở trạng thái AVAILABLE.",
        "1. Người dùng chọn chức năng 'Đăng tin phòng' (QLBD_BM1).\n2. Người dùng nhập thông tin: Tiêu đề, Địa chỉ chi tiết, Giá phòng, Tiền điện/nước, Số lượng người cần tìm thêm.\n3. Người dùng tick chọn các tiện ích (Máy lạnh, Gác lửng, Máy giặt, Giờ giấc tự do).\n4. Người dùng tải lên hình ảnh phòng trọ thực tế.\n5. Người dùng nhấn nút 'Đăng tin'.\n6. Hệ thống kiểm tra dữ liệu, lưu bài đăng vào CSDL và gán trạng thái AVAILABLE.\n7. Bài đăng xuất hiện công khai trên bảng tin chung.",
        "Không có.",
        "2a. Giá phòng nhập vào để trống hoặc bằng 0: Báo lỗi 'Vui lòng nhập giá phòng hợp lệ'.\n4a. Dung lượng ảnh vượt quá 5MB hoặc sai định dạng: Hệ thống báo 'Chỉ hỗ trợ tệp ảnh PNG, JPG dưới 5MB'."
    )

    # UC-47/48
    add_usecase_spec_table(
        "UC-47/48", "Đề xuất và quản lý lịch hẹn xem phòng trọ",
        "Người dùng (User), Chủ phòng (Room Host)",
        "Hai bên đã có kết nối Active sau Double Opt-in; bài đăng phòng trọ vẫn còn chỗ trống.",
        "Một lịch hẹn (ViewingAppointment) được xác nhận; hệ thống kích hoạt nhắc lịch trước 24 giờ.",
        "1. Người dùng A truy cập hồ sơ kết nối với Chủ phòng B và chọn 'Hẹn xem phòng' (QLLH_BM1).\n2. A chọn bài đăng phòng của B, nhập ngày giờ hẹn trong tương lai và địa điểm gặp.\n3. A nhấn 'Gửi đề xuất lịch hẹn'.\n4. Hệ thống tạo lịch hẹn ở trạng thái PENDING và gửi thông báo cho B.\n5. B mở thông báo, kiểm tra thời gian và nhấn 'Xác nhận lịch hẹn'.\n6. Hệ thống chuyển trạng thái lịch hẹn sang CONFIRMED.\n7. Hệ thống tự động đặt lịch nhắc nhở trước thời điểm hẹn 24 giờ cho cả hai bên.",
        "5a. B không rảnh vào giờ đó: B chọn 'Đề xuất giờ khác'; A nhận thông báo giờ hẹn mới để xác nhận lại.\n5b. B bấm 'Từ chối': Lịch hẹn chuyển sang REJECTED.",
        "2a. A chọn thời gian trong quá khứ: Hệ thống báo lỗi 'Thời gian hẹn phải ở trong tương lai'.\n5c. Một trong hai bên bấm Hủy kết nối: Toàn bộ lịch hẹn xem phòng chưa diễn ra tự động bị CANCELLED."
    )

    # UC-54
    add_usecase_spec_table(
        "UC-54", "Kiểm duyệt và ẩn bài đăng phòng vi phạm",
        "Quản trị viên (Admin)",
        "Quản trị viên đã đăng nhập thành công vào trang quản trị hệ thống.",
        "Bài đăng vi phạm bị ẩn khỏi hệ thống; người đăng và người báo cáo nhận được thông báo kết quả.",
        "1. Quản trị viên truy cập mục 'Quản lý báo cáo phòng trọ' (FR-53).\n2. Hệ thống hiển thị danh sách các bài đăng bị người dùng báo cáo (lý do: Phòng ảo, Lừa đảo cọc, Sai địa chỉ).\n3. Admin chọn một báo cáo để xem chi tiết bài đăng và hình ảnh bằng chứng đối chứng.\n4. Admin xác minh nội dung vi phạm.\n5. Admin nhấn nút 'Ẩn bài đăng vi phạm', nhập lý do xử phạt.\n6. Hệ thống chuyển trạng thái hiển thị của bài đăng sang HIDDEN, bài đăng lập tức biến mất khỏi kết quả tìm kiếm.\n7. Hệ thống gửi thông báo cảnh cáo tới chủ bài đăng và thông báo cảm ơn tới người gửi báo cáo.",
        "4a. Nếu nội dung bài đăng trung thực, báo cáo sai sự thật: Admin nhấn 'Bác bỏ báo cáo' (Dismissed).",
        "Không có."
    )

    # ==========================================
    # KẾT LUẬN & HƯỚNG PHÁT TRIỂN
    # ==========================================
    add_h1("KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN")
    add_p("Tài liệu Mô hình hóa yêu cầu phần mềm của đề tài 'Xây dựng ứng dụng tìm kiếm và ghép bạn cùng thuê trọ theo tiêu chí (Roommate Matching Hub)' đã hoàn thành xuất sắc các mục tiêu nghiên cứu và đặc tả kỹ thuật đặt ra:")
    add_p("1. Đã khảo sát toàn diện hiện trạng thực tế và đối chiếu với các nền tảng công nghệ phổ biến, làm nổi bật được giá trị thực tiễn và tính cấp thiết của đề tài đối với cộng đồng sinh viên.")
    add_p("2. Đã xây dựng danh mục 54 yêu cầu chức năng (FR-01 → FR-54) theo chuẩn IEEE và chuẩn định dạng kỹ thuật của môn học, bao phủ trọn vẹn từ quản lý tài khoản, khảo sát 5 tiêu chí lối sống, thuật toán Matching Score, ghép đôi Double Opt-in, quản lý lịch hẹn xem phòng đến kiểm duyệt an toàn của Admin.")
    add_p("3. Đã mô hình hóa trực quan 6 phân hệ Lược đồ Use Case với các quan hệ phụ thuộc <<include>> và <<extend>> chặt chẽ, đi kèm Ma trận truy vết Traceability Matrix và 7 bảng Đặc tả Use Case chi tiết.")
    add_p("Hướng phát triển tiếp theo: Nhóm sẽ tiến hành thiết kế kiến trúc hệ thống chi tiết (Class Diagram, Sequence Diagram), thiết kế cơ sở dữ liệu vật lý trên MySQL và hoàn thiện mã nguồn Backend Spring Boot kết hợp giao diện Frontend Flutter để đưa sản phẩm vào thử nghiệm thực tế tại khu vực Làng Đại học TP.HCM.")

    # Save to file
    output_path = os.path.join("docs", "Nhom13_Mohinhhoayeucau.docx")
    doc.save(output_path)
    print(f"Document created successfully at: {output_path}")

if __name__ == "__main__":
    create_full_document()
