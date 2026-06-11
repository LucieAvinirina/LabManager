import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/reservation_model.dart';
import '../providers/reservations_provider.dart';
import 'reservation_form_screen.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// PlanningScreen — Calendrier interactif des réservations
// • Tous rôles : voit les créneaux occupés/libres
// • Admin      : voit toutes les réservations + peut confirmer/refuser
// • Étudiant/Enseignant : voit ses propres réservations + peut créer
// ─────────────────────────────────────────────────────────────────────────────
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});
 
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}
 
class _PlanningScreenState extends State<PlanningScreen> {
  DateTime          _focusedDay    = DateTime.now();
  DateTime          _selectedDay   = DateTime.now();
  CalendarFormat    _calendarFormat = CalendarFormat.month;
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsProvider>().loadAll();
    });
  }
 
  // ─── Réservations pour un jour donné ──────────────────────
  List<ReservationModel> _getEventsForDay(
      DateTime day, List<ReservationModel> all) {
    return all.where((r) {
      return isSameDay(r.dateHeureDebut, day);
    }).toList();
  }
 
  // ─── Couleur du marqueur calendrier ───────────────────────
  Color _markerColor(List<ReservationModel> events) {
    if (events.any((e) => e.statut == 'En attente')) return AppColors.warning;
    if (events.any((e) => e.statut == 'Confirmée'))  return AppColors.available;
    return AppColors.disabled;
  }
 
  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<ReservationsProvider>();
    final all     = prov.reservations;
    final events  = _getEventsForDay(_selectedDay, all);
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Planning des réservations'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            onPressed: () => prov.loadAll(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReservationFormScreen()),
        ).then((_) => prov.loadAll()),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon:            const Icon(Icons.add),
        label:           const Text('Réserver'),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color:     AppColors.primary,
              onRefresh: () => prov.loadAll(),
              child:     _buildBody(context, all, events),
            ),
    );
  }
 
  Widget _buildBody(
    BuildContext context,
    List<ReservationModel> all,
    List<ReservationModel> events,
  ) {
    return Column(
      children: [
        // ─── Légende statuts ──────────────────────────────
        _buildLegend(),
 
        // ─── TableCalendar ────────────────────────────────
        Container(
          color: AppColors.white,
          child: TableCalendar<ReservationModel>(
            locale:             'fr_FR',
            firstDay:           DateTime.now().subtract(const Duration(days: 365)),
            lastDay:            DateTime.now().add(const Duration(days: 365)),
            focusedDay:         _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            calendarFormat:     _calendarFormat,
            startingDayOfWeek:  StartingDayOfWeek.monday,
            eventLoader:        (day) => _getEventsForDay(day, all),
 
            // ─── Style ────────────────────────────────────
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.3),
                shape:        BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.available,
                shape: BoxShape.circle,
              ),
              markersMaxCount:     3,
              outsideDaysVisible:  false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible:     true,
              titleCentered:           true,
              formatButtonShowsNext:   false,
              formatButtonDecoration: BoxDecoration(
                border: Border.fromBorderSide(
                    BorderSide(color: AppColors.primary)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              formatButtonTextStyle: TextStyle(color: AppColors.primary),
            ),
 
            // ─── Marqueurs colorés par statut ─────────────
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                final color = _markerColor(events.cast<ReservationModel>());
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      events.length.clamp(0, 3),
                      (_) => Container(
                        width:  6, height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
 
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay  = focused;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
            },
          ),
        ),
 
        const Divider(height: 1),
 
        // ─── En-tête du jour sélectionné ──────────────────
        _buildDayHeader(events),
 
        // ─── Liste des réservations du jour ───────────────
        Expanded(
          child: events.isEmpty
              ? _buildEmptyDay()
              : ListView.builder(
                  padding:     const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount:   events.length,
                  itemBuilder: (_, i) => _ReservationCalendarCard(
                    reservation: events[i],
                  ),
                ),
        ),
      ],
    );
  }
 
  // ─── Légende ──────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _LegendDot(color: AppColors.warning,   label: 'En attente'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.available, label: 'Confirmée'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.disabled,  label: 'Terminée/Annulée'),
        ],
      ),
    );
  }
 
  // ─── Titre du jour sélectionné ────────────────────────────
  Widget _buildDayHeader(List<ReservationModel> events) {
    final label = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay);
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color:   AppColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          Text(
            label[0].toUpperCase() + label.substring(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   14,
              color:      AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          if (events.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:        AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${events.length}',
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
 
  // ─── Aucune réservation ce jour ───────────────────────────
  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available,
              size: 56,
              color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text(
            'Aucune réservation ce jour',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReservationFormScreen()),
            ).then((_) =>
                context.read<ReservationsProvider>().loadAll()),
            icon:  const Icon(Icons.add),
            label: const Text('Créer une réservation'),
          ),
        ],
      ),
    );
  }
}
 
// ─── Widget : Carte réservation dans le calendrier ───────────────────────────
// ─── Widget : Carte réservation dans le calendrier (lecture seule) ────────────
// Les actions (Confirmer/Refuser/Annuler) sont gérées dans MesReservationsScreen
class _ReservationCalendarCard extends StatelessWidget {
  final ReservationModel reservation;
 
  const _ReservationCalendarCard({required this.reservation});
 
  @override
  Widget build(BuildContext context) {
    final color = reservation.statutColor;
    final fmt   = DateFormat('HH:mm');
 
    return Card(
      margin:    const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ─── Barre colorée à gauche ───────────────────
            Container(
              width: 5,
              decoration: BoxDecoration(
                color:        color,
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // ─── Contenu ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heure + badge statut
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${fmt.format(reservation.dateHeureDebut)} — ${fmt.format(reservation.dateHeureFin)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:   13,
                            color:      AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _StatusBadge(statut: reservation.statut, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
 
                    // Nom utilisateur + type réservation
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reservation.fullName,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reservation.isSalleEntiere
                                ? 'Salle entière'
                                : 'Poste individuel',
                            style: const TextStyle(
                                color: AppColors.primaryLight, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
 
                    // Équipements
                    if (reservation.equipements.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reservation.equipements
                            .take(3)
                            .map((e) => e['nom'] as String)
                            .join(', '),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
 
                    // Motif
                    if (reservation.motif != null &&
                        reservation.motif!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reservation.motif!,
                        style: const TextStyle(
                          fontSize:  11,
                          color:     AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _StatusBadge extends StatelessWidget {
  final String statut;
  final Color  color;
 
  const _StatusBadge({required this.statut, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        statut,
        style: TextStyle(
          color:      color,
          fontSize:   10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
 
// ─── Widget : Point de légende ────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
 
  const _LegendDot({required this.color, required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
 