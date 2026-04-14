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
    // 🎨 TỰ ĐỘNG CHUYỂN MÀU THEO CHẾ ĐỘ SÁNG / TỐI
    Color bgColor = isDarkMode ? const Color(0xFF1E1F22) : const Color(0xFFF0F4F9); // Tối: Xám đen | Sáng: Trắng xanh nhẹ
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color iconColor = isDarkMode ? Colors.white70 : Colors.black54;
    Color dividerColor = isDarkMode ? Colors.white10 : Colors.black12;
    Color hoverColor = isDarkMode ? const Color(0xFF2A2A35) : Colors.blue.withOpacity(0.08);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ================= HEADER: NÚT NEW CHAT =================
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: Text(t("Đoạn chat mới", "New Chat"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: onNewChat,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.menu_open, color: iconColor),
                    onPressed: onToggleSidebar,
                    tooltip: t("Đóng thanh bên", "Close sidebar"),
                  ),
                ]
              ],
            ),
          ),
          
          // ================= DANH SÁCH LỊCH SỬ CHAT =================
          Expanded(
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
                      child: Text(
                        entry.key, 
                        style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                    ...entry.value.map((session) {
                      bool isActive = session['id'] == currentSessionId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: isActive ? hoverColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                          onTap: () => onLoadChatHistory(session['id']),
                          
                          // MENU 3 CHẤM (ĐỔI TÊN, TÓM TẮT, XÓA)
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 16, color: iconColor),
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
                      );
                    }).toList()
                  ],
                );
              }).toList(),
            ),
          ),

          Divider(color: dividerColor, height: 1),

          // ================= BOTTOM ACTIONS (ADMIN & SETTINGS) =================
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                if (role == 'admin')
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.dashboard_customize, color: Colors.orangeAccent, size: 18),
                      title: Text(t("Quản trị hệ thống", "Admin Dashboard"), style: TextStyle(color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange, fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: unansweredCount > 0 
                          ? Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text('$unansweredCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                          : null,
                      onTap: onOpenAdmin,
                    ),
                  ),
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: Icon(Icons.settings_outlined, color: iconColor, size: 18),
                  title: Text(t("Cài đặt", "Settings"), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                  onTap: onOpenSettings,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}