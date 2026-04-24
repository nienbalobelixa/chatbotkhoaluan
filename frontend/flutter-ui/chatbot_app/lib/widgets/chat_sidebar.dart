import 'package:flutter/material.dart';

class ChatSidebar extends StatefulWidget {
  final bool isDarkMode;
  final bool isDesktop;
  final bool isSidebarOpen;
  
  // Các biến dữ liệu
  final List<dynamic> chatSessions; // List gốc để search
  final List<String> pinnedSessionIds; // List các ID đã ghim
  final Map<String, List<dynamic>> groupedSessions;
  final String? currentSessionId;
  final String role;
  final int unansweredCount;
  final String Function(String, String) t;

  // Các hàm tương tác
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewChat;
  final Function(String) onLoadChatHistory;
  final Function(String, String) onRename;
  final Function(String) onSummarize;
  final Function(String) onDelete;
  final Function(String) onTogglePin; // Hàm ghim
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAdmin;

  const ChatSidebar({
    Key? key,
    required this.isDarkMode,
    required this.isDesktop,
    required this.isSidebarOpen,
    required this.chatSessions,
    required this.pinnedSessionIds,
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
    required this.onTogglePin,
    required this.onOpenSettings,
    required this.onOpenAdmin,
  }) : super(key: key);

  @override
  _ChatSidebarState createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDarkMode ? const Color(0xFF1E1F22) : const Color(0xFFF0F4F9);
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    Color iconColor = widget.isDarkMode ? Colors.white70 : Colors.black54;
    Color hoverColor = widget.isDarkMode ? Colors.white10 : Colors.black12;
    Color activeBg = widget.isDarkMode ? const Color(0xFF004A77).withOpacity(0.4) : const Color(0xFFD3E3FD);
    Color activeText = widget.isDarkMode ? const Color(0xFFC2E7FF) : const Color(0xFF041E49);

    // Lọc danh sách nếu đang tìm kiếm
    List<dynamic> filteredSessions = [];
    if (_isSearching && _searchQuery.isNotEmpty) {
      filteredSessions = widget.chatSessions.where((s) {
        String title = s['title']?.toString().toLowerCase() ?? "";
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. THANH ĐIỀU HƯỚNG TRÊN CÙNG (Giống Gemini)
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  color: iconColor,
                  tooltip: widget.t("Thu gọn trình đơn", "Collapse menu"),
                  onPressed: widget.onToggleSidebar,
                ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  color: iconColor,
                  tooltip: widget.t("Tìm kiếm", "Search"),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = "";
                        _searchController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // 2. THANH TÌM KIẾM (Chỉ hiện khi bấm nút Kính lúp)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.t("Tìm cuộc trò chuyện...", "Search chats..."),
                  hintStyle: TextStyle(color: iconColor, fontSize: 14),
                  filled: true,
                  fillColor: widget.isDarkMode ? Colors.black26 : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

          // 3. NÚT TẠO CUỘC TRÒ CHUYỆN MỚI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: InkWell(
              onTap: widget.onNewChat,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF2A2A35) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: widget.isDarkMode ? Colors.transparent : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_square, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 15),
                    Text(
                      widget.t("Cuộc trò chuyện mới", "New Chat"),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 4. DANH SÁCH CHAT
          Expanded(
            child: _isSearching && _searchQuery.isNotEmpty
                // GIAO DIỆN KHI ĐANG TÌM KIẾM
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredSessions.length,
                    itemBuilder: (ctx, i) => _buildChatItem(filteredSessions[i], activeBg, activeText, textColor, hoverColor, iconColor),
                  )
                // GIAO DIỆN BÌNH THƯỜNG (Có phân nhóm)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      // KHU VỰC ĐÃ GHIM
                      if (widget.pinnedSessionIds.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 15, top: 15, bottom: 5),
                          child: Text(widget.t("Đã ghim", "Pinned"), style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        ...widget.chatSessions
                            .where((s) => widget.pinnedSessionIds.contains(s['id'].toString()))
                            .map((s) => _buildChatItem(s, activeBg, activeText, textColor, hoverColor, iconColor))
                            .toList(),
                      ],

                      // KHU VỰC THEO THỜI GIAN (Hôm nay, Hôm qua...)
                      ...widget.groupedSessions.entries.map((entry) {
                        // Lọc bỏ các chat đã ghim để không bị trùng lặp
                        var unpinnedSessions = entry.value.where((s) => !widget.pinnedSessionIds.contains(s['id'].toString())).toList();
                        if (unpinnedSessions.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 15, bottom: 5),
                              child: Text(entry.key, style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            ...unpinnedSessions.map((s) => _buildChatItem(s, activeBg, activeText, textColor, hoverColor, iconColor)).toList(),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
          ),

          // 5. THANH CÔNG CỤ BOTTOM (Cài đặt, Admin)
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                if (widget.role == 'admin')
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.orangeAccent, size: 20),
                    title: Text("Trang Quản trị", style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: widget.unansweredCount > 0
                        ? Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text('${widget.unansweredCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                        : null,
                    onTap: widget.onOpenAdmin,
                  ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(Icons.settings_outlined, color: iconColor, size: 20),
                  title: Text(widget.t("Cài đặt", "Settings"), style: TextStyle(color: textColor, fontSize: 14)),
                  onTap: widget.onOpenSettings,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // WIDGET CON: VẼ TỪNG DÒNG CUỘC TRÒ CHUYỆN KÈM MENU 3 CHẤM
  Widget _buildChatItem(dynamic s, Color activeBg, Color activeText, Color textColor, Color hoverColor, Color iconColor) {
    bool isActive = widget.currentSessionId == s['id'].toString();
    bool isPinned = widget.pinnedSessionIds.contains(s['id'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(20), // Bo cong giống Gemini
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 15, right: 5),
        minLeadingWidth: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        hoverColor: hoverColor,
        // Icon chat nhỏ nhắn nhắn
        leading: Icon(Icons.chat_bubble_outline, size: 16, color: isActive ? activeText : iconColor),
        title: Text(
          s['title'] ?? widget.t("Trò chuyện mới", "New Chat"),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? activeText : textColor,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Báo hiệu đang ghim
            if (isPinned)
              Icon(Icons.push_pin, size: 14, color: isActive ? activeText : iconColor),
              
            // MENU 3 CHẤM BÊN PHẢI (KHI BẤM SẼ XỔ RA CHỨC NĂNG)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 16, color: isActive ? activeText : iconColor),
              color: widget.isDarkMode ? const Color(0xFF2F2F2F) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'pin') widget.onTogglePin(s['id'].toString());
                if (value == 'rename') widget.onRename(s['id'].toString(), s['title'] ?? "");
                if (value == 'summarize') widget.onSummarize(s['id'].toString());
                if (value == 'delete') widget.onDelete(s['id'].toString());
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'pin',
                  child: Row(children: [Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18, color: textColor), const SizedBox(width: 10), Text(isPinned ? widget.t("Bỏ ghim", "Unpin") : widget.t("Ghim", "Pin"), style: TextStyle(color: textColor))]),
                ),
                PopupMenuItem<String>(
                  value: 'rename',
                  child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: textColor), const SizedBox(width: 10), Text(widget.t("Đổi tên", "Rename"), style: TextStyle(color: textColor))]),
                ),
                PopupMenuItem<String>(
                  value: 'summarize',
                  child: Row(children: [Icon(Icons.auto_awesome, size: 18, color: Colors.blueAccent), const SizedBox(width: 10), Text(widget.t("Tóm tắt", "Summarize"), style: TextStyle(color: textColor))]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 10), Text(widget.t("Xóa", "Delete"), style: const TextStyle(color: Colors.redAccent))]),
                ),
              ],
            ),
          ],
        ),
        onTap: () => widget.onLoadChatHistory(s['id'].toString()),
      ),
    );
  }
}