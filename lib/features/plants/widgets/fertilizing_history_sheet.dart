import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/fertilize_service.dart';

class FertilizingHistorySheet extends StatelessWidget {
  final String plantId;

  const FertilizingHistorySheet({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final service = FertilizeService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(width: 40, height: 4, color: Colors.grey),
          const SizedBox(height: 16),

          const Text(
            "Fertilizing history",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.getFertilizingHistory(plantId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;

                if (items.isEmpty) {
                  return const Center(child: Text("No fertilizing yet 🌱"));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return ListTile(
                      leading: const Icon(Icons.science),
                      title: Text(item['fertilizerName']),
                      subtitle: Text(
                        DateFormat('d MMM y').format(item['appliedAt']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
