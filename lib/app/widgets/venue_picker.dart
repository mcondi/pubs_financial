import 'package:flutter/material.dart';
import '../models/venue.dart';

class VenuePicker extends StatelessWidget {
  const VenuePicker({
    super.key,
    required this.venues,
    required this.selectedVenueId,
    required this.onPickVenue,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.backgroundColor,
    required this.textColor,
  });

  final List<Venue> venues;
  final int selectedVenueId;
  final void Function(int id) onPickVenue;

  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final selected = venues.firstWhere(
      (v) => v.id == selectedVenueId,
      orElse: () => venues.first,
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<int>(
              initialValue: selected.id,
              onSelected: onPickVenue,
              itemBuilder: (context) => venues
                  .map((v) => PopupMenuItem<int>(value: v.id, child: Text(v.name)))
                  .toList(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected.name,
                      style: TextStyle(color: textColor, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down, color: textColor.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onPrev,
            icon: Icon(
              Icons.arrow_circle_left,
              size: 32,
              color: textColor.withValues(alpha: canPrev ? 0.9 : 0.3),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.arrow_circle_right,
              size: 32,
              color: textColor.withValues(alpha: canNext ? 0.9 : 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
