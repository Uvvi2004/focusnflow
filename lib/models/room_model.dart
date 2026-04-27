import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String roomId;
  final String name;
  final String building;
  final String floor;
  final int capacity;
  final String status; // open / occupied / reserved
  final List<String> amenities;
  final DateTime updatedAt;

  RoomModel({
    required this.roomId,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.status,
    required this.amenities,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'status': status,
      'amenities': amenities,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      roomId: id,
      name: map['name'] ?? '',
      building: map['building'] ?? '',
      floor: map['floor'] ?? '',
      capacity: map['capacity'] ?? 0,
      status: map['status'] ?? 'open',
      amenities: List<String>.from(map['amenities'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}