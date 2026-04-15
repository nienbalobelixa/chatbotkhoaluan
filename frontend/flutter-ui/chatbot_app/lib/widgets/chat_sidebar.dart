import 'package:flutter/material.dart';

class ChatSidebar extends StatelessWidget {
  final bool isDarkMode;
  final bool isDesktop;
  final bool isSidebarOpen;
  final Map<String, List<dynamic>> groupedSessions;
  final String? currentSessionId;
  final String role;
  final int unansweredCount;
  final String Function(String, String) t;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewChat;
  final Function(String) onLoadChatHistory;
  final Function(String, String) onRename;
  final Function(String) onSummarize;
  final Function(String) onDelete;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAdmin;

  const ChatSidebar({
    Key? key,
    required this.isDarkMode,
    required this.isDesktop,
    required this.isSidebarOpen,
    required this.groupedSessions,
    required this.currentSessionId,
    required this.role,
    required this.unansweredCount,
    required this.t,
    required this.onToggleSidebar,
    required this.onNewChat,
    required this.onLoadChatHistory,
    required this.onRename,
    required this.onSummarize,
    required this.onDelete,
    required this.onOpenSettings,
    required this.onOpenAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎨 HỆ THỐNG MÀU SẮC ĐỘNG (SÁNG / TỐI)
    Color bgColor = isDarkMode ? const Color(0xFF1E1F22) : const Color(0xFFF0F4F9);
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color iconColor = isDarkMode ? Colors.white70 : Colors.black54;
    Color dividerColor = isDarkMode ? Colors.white10 : Colors.black12;
    Color activeBgColor = isDarkMode ? const Color(0xFF2A2A35) : Colors.blue.withOpacity(0.08);
    Color hoverColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= 1. HEADER: BRAND & MENU =================
          _SidebarBrandHeader(
            isDesktop: isDesktop,
            textColor: textColor,
            iconColor: iconColor,
            hoverColor: hoverColor,
            t: t,
            onToggleSidebar: onToggleSidebar,
          ),

          // ================= 2. ACTION: NÚT CHAT MỚI =================
          _SidebarActionArea(
            t: t,
            onNewChat: onNewChat,
          ),

          const SizedBox(height: 10),
          
          // ================= 3. LIST: LỊCH SỬ CHAT =================
          _ChatHistoryList(
            groupedSessions: groupedSessions,
            currentSessionId: currentSessionId,
            isDarkMode: isDarkMode,
            textColor: textColor,
            iconColor: iconColor,
            activeBgColor: activeBgColor,
            hoverColor: hoverColor,
            t: t,
            onLoadChatHistory: onLoadChatHistory,
            onRename: onRename,
            onSummarize: onSummarize,
            onDelete: onDelete,
          ),

          Divider(color: dividerColor, height: 1),

          // ================= 4. FOOTER: QUẢN TRỊ & CÀI ĐẶT =================
          _SidebarFooter(
            role: role,
            unansweredCount: unansweredCount,
            isDarkMode: isDarkMode,
            textColor: textColor,
            iconColor: iconColor,
            hoverColor: hoverColor,
            t: t,
            onOpenAdmin: onOpenAdmin,
            onOpenSettings: onOpenSettings,
          )
        ],
      ),
    );
  }
}

// ============================================================================
// CÁC COMPONENT CON (ĐƯỢC TÁCH RIÊNG ĐỂ DỄ BẢO TRÌ VÀ THÊM HIỆU ỨNG)
// ============================================================================

// 🧩 COMPONENT 1: BRAND HEADER (Logo + Tên App + Nút Đóng/Mở góc phải)
class _SidebarBrandHeader extends StatelessWidget {
  final bool isDesktop;
  final Color textColor;
  final Color iconColor;
  final Color hoverColor;
  final String Function(String, String) t;
  final VoidCallback onToggleSidebar;

  const _SidebarBrandHeader({required this.isDesktop, required this.textColor, required this.iconColor, required this.hoverColor, required this.t, required this.onToggleSidebar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 10, 10),
      child: Row(
        children: [
          // Icon Nhấp nháy đặc trưng của AI
          Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 10),
          // Tên Ứng dụng
          Expanded(
            child: Text(
              "ABC TECH AI", 
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ),
          // Nút Menu góc phải
          if (isDesktop)
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.hardEdge,
              child: IconButton(
                icon: Icon(Icons.menu_open, color: iconColor),
                onPressed: onToggleSidebar,
                tooltip: t("Đóng thanh bên", "Close sidebar"),
                hoverColor: hoverColor,
                splashRadius: 20,
              ),
            ),
        ],
      ),
    );
  }
}

// 🧩 COMPONENT 2: NÚT NEW CHAT (Nằm tách biệt bên dưới, full chiều ngang)
class _SidebarActionArea extends StatelessWidget {
  final String Function(String, String) t;
  final VoidCallback onNewChat;

  const _SidebarActionArea({required this.t, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: SizedBox(
        width: double.infinity, // Kéo dãn nút bấm full 100% chiều ngang
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: Text(t("Đoạn chat mới", "New Chat"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: onNewChat,
        ),
      ),
    );
  }
}

// 🧩 COMPONENT 3: DANH SÁCH LỊCH SỬ CHAT (Có hiệu ứng Hover)
class _ChatHistoryList extends StatelessWidget {
  final Map<String, List<dynamic>> groupedSessions;
  final String? currentSessionId;
  final bool isDarkMode;
  final Color textColor;
  final Color iconColor;
  final Color activeBgColor;
  final Color hoverColor;
  final String Function(String, String) t;
  final Function(String) onLoadChatHistory;
  final Function(String, String) onRename;
  final Function(String) onSummarize;
  final Function(String) onDelete;

  const _ChatHistoryList({required this.groupedSessions, required this.currentSessionId, required this.isDarkMode, required this.textColor, required this.iconColor, required this.activeBgColor, required this.hoverColor, required this.t, required this.onLoadChatHistory, required this.onRename, required this.onSummarize, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        physics: const BouncingScrollPhysics(),
        children: groupedSessions.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox(); 
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 15, bottom: 5),
                child: Text(entry.key, style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ...entry.value.map((session) {
                bool isActive = session['id'] == currentSessionId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isActive ? activeBgColor : Colors.transparent, 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  // Thẻ Material + InkWell tạo hiệu ứng Hover tuyệt đẹp
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: hoverColor,
                      onTap: () => onLoadChatHistory(session['id']),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: Icon(Icons.chat_bubble_outline, size: 16, color: isActive ? Colors.blueAccent : iconColor),
                        title: Text(
                          session['title'], 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: TextStyle(
                            color: isActive ? Colors.blueAccent : textColor, 
                            fontSize: 13, 
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500
                          )
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 16, color: iconColor),
                          tooltip: t("Tùy chọn", "Options"),
                          color: isDarkMode ? const Color(0xFF2A2A35) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (val) {
                            if (val == 'rename') onRename(session['id'], session['title']);
                            else if (val == 'summarize') onSummarize(session['id']);
                            else if (val == 'delete') onDelete(session['id']);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 16, color: textColor), const SizedBox(width: 8), Text(t("Đổi tên", "Rename"), style: TextStyle(color: textColor, fontSize: 13))])),
                            PopupMenuItem(value: 'summarize', child: Row(children: [Icon(Icons.short_text, size: 16, color: textColor), const SizedBox(width: 8), Text(t("Tóm tắt", "Summarize"), style: TextStyle(color: textColor, fontSize: 13))])),
                            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 16, color: Colors.redAccent), const SizedBox(width: 8), Text(t("Xóa", "Delete"), style: const TextStyle(color: Colors.redAccent, fontSize: 13))])),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList()
            ],
          );
        }).toList(),
      ),
    );
  }
}

// 🧩 COMPONENT 4: FOOTER (Quản trị hệ thống & Cài đặt)
class _SidebarFooter extends StatelessWidget {
  final String role;
  final int unansweredCount;
  final bool isDarkMode;
  final Color textColor;
  final Color iconColor;
  final Color hoverColor;
  final String Function(String, String) t;
  final VoidCallback onOpenAdmin;
  final VoidCallback onOpenSettings;

  const _SidebarFooter({required this.role, required this.unansweredCount, required this.isDarkMode, required this.textColor, required this.iconColor, required this.hoverColor, required this.t, required this.onOpenAdmin, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          // Nút Quản trị (Chỉ hiện nếu là Admin)
          if (role == 'admin')
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: Colors.orangeAccent.withOpacity(0.2),
                  onTap: onOpenAdmin,
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.dashboard_customize, color: Colors.orangeAccent, size: 18),
                    title: Text(
                      t("Quản trị hệ thống", "Admin Dashboard"), 
                      style: TextStyle(color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange, fontSize: 13, fontWeight: FontWeight.bold)
                    ),
                    trailing: unansweredCount > 0 
                        ? Container(
                            padding: const EdgeInsets.all(5), 
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), 
                            child: Text('$unansweredCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                          )
                        : null,
                  ),
                ),
              ),
            ),
          
          // Nút Cài đặt (Luôn hiện)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: hoverColor,
              onTap: onOpenSettings,
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: Icon(Icons.settings_outlined, color: iconColor, size: 18),
                title: Text(
                  t("Cài đặt", "Settings"), 
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}