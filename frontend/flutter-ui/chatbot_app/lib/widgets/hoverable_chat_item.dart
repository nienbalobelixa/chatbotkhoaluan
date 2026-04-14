import 'package:flutter/material.dart';

class HoverableChatItem extends StatefulWidget {
  final String title;
  final IconData leadingIcon;
  final Widget? trailing; 
  final bool isActive;
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color? customColor; 

  const HoverableChatItem({
    Key? key,
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.isDarkMode,
    this.leadingIcon = Icons.chat_bubble_outline,
    this.trailing,
    this.customColor,
  }) : super(key: key);

  @override
  State<HoverableChatItem> createState() => _HoverableChatItemState();
}

class _HoverableChatItemState extends State<HoverableChatItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color baseColor = widget.customColor ?? (widget.isDarkMode ? Colors.white70 : Colors.black87);
    Color activeColor = widget.customColor ?? Colors.blueAccent;
    Color activeBgColor = widget.isDarkMode ? const Color(0xFF042B59) : const Color(0xFFD3E3FD);
    Color hoverBgColor = widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isActive ? activeBgColor : (_isHovering ? hoverBgColor : Colors.transparent),
          borderRadius: BorderRadius.circular(12), 
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.leadingIcon, size: 18, color: widget.isActive ? activeColor : baseColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isActive ? activeColor : baseColor,
                        fontSize: 13,
                        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!, 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}