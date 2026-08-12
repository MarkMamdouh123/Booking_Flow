import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment_model.dart';
import '../models/appointment_status.dart';
import '../models/availability_model.dart';
import '../models/service_model.dart';

class HiveService {
  static const String appointmentsBoxName = 'appointments_box';
  static const String availabilityBoxName = 'availability_box';
  static const String settingsBoxName = 'settings_box';
  static const String isDarkModeKey = 'is_dark_mode';

  // Available Default Services
  static const List<ServiceModel> defaultServices = [
    ServiceModel(
      id: 'srv_1',
      name: 'General Consultation',
      description: 'Comprehensive initial health & wellness assessment with personalized care plan.',
      durationMinutes: 30,
      price: 75.0,
      category: 'Medical',
      iconName: 'medical_services',
    ),
    ServiceModel(
      id: 'srv_2',
      name: 'Dental Cleaning & Checkup',
      description: 'Professional dental hygiene cleaning, polishing, and oral exam.',
      durationMinutes: 45,
      price: 120.0,
      category: 'Dental',
      iconName: 'cleaning_services',
    ),
    ServiceModel(
      id: 'srv_3',
      name: 'Executive Haircut & Styling',
      description: 'Custom styling, hot towel treatment, and precision scissor haircut.',
      durationMinutes: 45,
      price: 55.0,
      category: 'Grooming',
      iconName: 'content_cut',
    ),
    ServiceModel(
      id: 'srv_4',
      name: 'Deep Tissue Therapy',
      description: 'Targeted muscle tension relief massage therapy.',
      durationMinutes: 60,
      price: 95.0,
      category: 'Therapy',
      iconName: 'spa',
    ),
    ServiceModel(
      id: 'srv_5',
      name: 'Personal Fitness Coaching',
      description: 'One-on-one customized physical training and workout plan session.',
      durationMinutes: 60,
      price: 80.0,
      category: 'Fitness',
      iconName: 'fitness_center',
    ),
  ];

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register TypeAdapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AppointmentStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ServiceModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AppointmentModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DayScheduleAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(AvailabilityModelAdapter());

    // Open Boxes
    await Hive.openBox<AppointmentModel>(appointmentsBoxName);
    await Hive.openBox<AvailabilityModel>(availabilityBoxName);
    await Hive.openBox(settingsBoxName);

    // Seed mock data if empty
    await _seedMockDataIfNeeded();
  }

  // Box Getters
  static Box<AppointmentModel> get _appointmentsBox => Hive.box<AppointmentModel>(appointmentsBoxName);
  static Box<AvailabilityModel> get _availabilityBox => Hive.box<AvailabilityModel>(availabilityBoxName);
  static Box get _settingsBox => Hive.box(settingsBoxName);

  // Appointments CRUD
  static List<AppointmentModel> getAppointments() {
    return _appointmentsBox.values.toList()
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
  }

  static Future<void> saveAppointment(AppointmentModel appointment) async {
    await _appointmentsBox.put(appointment.id, appointment);
  }

  static Future<void> deleteAppointment(String id) async {
    await _appointmentsBox.delete(id);
  }

  // Availability Management
  static AvailabilityModel getAvailability() {
    if (_availabilityBox.isEmpty) {
      final defaultSched = AvailabilityModel.defaultSchedule();
      _availabilityBox.put('default', defaultSched);
      return defaultSched;
    }
    return _availabilityBox.get('default') ?? AvailabilityModel.defaultSchedule();
  }

  static Future<void> saveAvailability(AvailabilityModel availability) async {
    await _availabilityBox.put('default', availability);
  }

  // Theme Preference
  static bool isDarkMode() {
    return _settingsBox.get(isDarkModeKey, defaultValue: false) as bool;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put(isDarkModeKey, isDark);
  }

  // Seed Mock Data
  static Future<void> _seedMockDataIfNeeded() async {
    if (_appointmentsBox.isNotEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const uuid = Uuid();

    final sampleAppointments = [
      // Today Appointments
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Sarah Jenkins',
        clientPhone: '+1 (555) 234-5678',
        clientEmail: 'sarah.j@example.com',
        service: defaultServices[0], // General Consultation
        date: today,
        startTime: '09:30 AM',
        durationMinutes: 30,
        price: 75.0,
        status: AppointmentStatus.confirmed,
        notes: 'First time visitor. Prefers morning appointments.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Michael Chen',
        clientPhone: '+1 (555) 876-5432',
        clientEmail: 'mchen@techcorp.io',
        service: defaultServices[1], // Dental Cleaning
        date: today,
        startTime: '11:00 AM',
        durationMinutes: 45,
        price: 120.0,
        status: AppointmentStatus.pending,
        notes: 'Requested routine cleaning and checkup.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'David Miller',
        clientPhone: '+1 (555) 345-6789',
        clientEmail: 'd.miller@gmail.com',
        service: defaultServices[3], // Deep Tissue Therapy
        date: today,
        startTime: '02:30 PM',
        durationMinutes: 60,
        price: 95.0,
        status: AppointmentStatus.confirmed,
        notes: 'Lower back stiffness. Focus on shoulder area.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),

      // Tomorrow / Upcoming
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Emily Watson',
        clientPhone: '+1 (555) 901-2345',
        clientEmail: 'emily.w@designstudio.org',
        service: defaultServices[2], // Executive Haircut
        date: today.add(const Duration(days: 1)),
        startTime: '10:00 AM',
        durationMinutes: 45,
        price: 55.0,
        status: AppointmentStatus.confirmed,
        notes: 'Prefers quiet session.',
        createdAt: today.subtract(const Duration(hours: 5)),
      ),
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Robert Vance',
        clientPhone: '+1 (555) 432-1098',
        clientEmail: 'robert.v@vancesupply.com',
        service: defaultServices[4], // Fitness Coaching
        date: today.add(const Duration(days: 2)),
        startTime: '03:00 PM',
        durationMinutes: 60,
        price: 80.0,
        status: AppointmentStatus.pending,
        notes: 'Goal: Strength training program design.',
        createdAt: today,
      ),

      // Past Completed
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Jessica Taylor',
        clientPhone: '+1 (555) 678-9012',
        clientEmail: 'jtaylor@artistic.net',
        service: defaultServices[0],
        date: today.subtract(const Duration(days: 1)),
        startTime: '01:30 PM',
        durationMinutes: 30,
        price: 75.0,
        status: AppointmentStatus.completed,
        notes: 'Assessment completed. Follow up scheduled in 1 month.',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Alex Rodriguez',
        clientPhone: '+1 (555) 789-0123',
        clientEmail: 'alex.rod@sportsplus.com',
        service: defaultServices[3],
        date: today.subtract(const Duration(days: 2)),
        startTime: '04:00 PM',
        durationMinutes: 60,
        price: 95.0,
        status: AppointmentStatus.completed,
        notes: 'Post-marathon muscle recovery session.',
        createdAt: today.subtract(const Duration(days: 6)),
      ),

      // Cancelled
      AppointmentModel(
        id: 'apt_${uuid.v4().substring(0, 8)}',
        clientName: 'Amanda Lewis',
        clientPhone: '+1 (555) 123-4567',
        clientEmail: 'amanda.l@boutique.co',
        service: defaultServices[1],
        date: today.subtract(const Duration(days: 3)),
        startTime: '10:30 AM',
        durationMinutes: 45,
        price: 120.0,
        status: AppointmentStatus.cancelled,
        cancellationReason: 'Client had an urgent schedule conflict.',
        notes: 'Will call back to reschedule next week.',
        createdAt: today.subtract(const Duration(days: 7)),
      ),
    ];

    for (final apt in sampleAppointments) {
      await _appointmentsBox.put(apt.id, apt);
    }
  }
}
