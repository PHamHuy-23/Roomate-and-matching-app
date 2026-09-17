# Roommate Hub — Penpot handoff

Đây là nguồn thiết kế không phụ thuộc Figma. File `roommate-hub-master-board.svg` dùng SVG thuần và đã được import vào Penpot thành các layer vector có thể chỉnh sửa.

## Trạng thái Penpot

- Đã tạo ba page: `00 — Cover`, `01 — Design System`, `02 — Product Screens`.
- Đã import master board `2330 × 8800` với 746 layer vào Product Screens.
- Đã tạo token set `Core`: 13 màu, 7 spacing và 5 border radius.
- Đã tạo 14 component assets cho button, input, chip/status, message bubble và Candidate Card.
- Đã export QA trực quan cho Cover, Foundations, Components và toàn bộ Product Screens.
- Page đang mở khi bàn giao: `02 — Product Screens`.

## Import vào Penpot

File hiện đã được dựng qua Penpot MCP. Các bước dưới đây chỉ dùng khi cần tái tạo ở một workspace khác:

1. Đăng nhập Penpot và tạo file mới.
2. Chọn **Main menu → Import files** hoặc kéo `roommate-hub-master-board.svg` vào dashboard/canvas.
3. Tạo ba page: `00 — Cover`, `01 — Design System`, `02 — Product Screens`.
4. Kết nối plugin MCP chính chủ trong editor để tái tạo token và component library.

## Nguồn chuẩn

- Token: `../design-tokens/roommate-hub.tokens.json`
- Theme Flutter: `../../frontend/lib/theme/roommate_hub_theme.dart`
- App icon: `../design-assets/roommate-hub-app-icon.svg`
- Contract màn hình: `../UI_UX_HANDOFF.md`

## Phạm vi board

- Authentication A01–A04
- Preference survey B01–B04
- Discover và compatibility C01–C04
- Requests, room feed và profile
- Chat H01–H05, gồm inbox, conversation, attachment-disabled, safety menu và ended state
- Admin G01 và chi tiết I01–I04, gồm report, user, room post và confirmation/audit

## Tái tạo board

Chạy `node docs/penpot/build_penpot_board.js` từ root repository.

Không đưa token đăng nhập, cookie hoặc OAuth state vào file thiết kế hay repository.
