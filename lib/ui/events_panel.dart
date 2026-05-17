import 'package:flutter/material.dart';
import 'package:flutter_grits/ui/events_logger.dart';

/// Панель отображения событий
class EventsPanel extends StatelessWidget {
  final EventsLogger logger;
  final String? roomFilter;

  const EventsPanel({
    super.key,
    required this.logger,
    this.roomFilter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logger,
      builder: (context, _) {
        final events = roomFilter != null
            ? logger.getEventsByRoom(roomFilter)
            : logger.events;

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'No events yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventTile(event: event);
          },
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final GameEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(event.icon, size: 16, color: event.color),
          const SizedBox(width: 8),
          Text(
            event.formattedTime,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: event.color,
                  ),
                ),
                if (event.message != null)
                  Text(
                    event.message!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (event.roomId != null)
                  Text(
                    'Room: ${event.roomId}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
