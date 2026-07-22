import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/emergency_contacts_provider.dart';
import '../providers/patient_guardians_provider.dart';
import '../../../infrastructure/models/emergency_contact_model.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Contactos de Emergencia',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(context),
        backgroundColor: const Color(0xFF023E8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Añadir Contacto',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildDigitalGuardianSection(context, ref),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 32, color: Colors.grey),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Directorio Telefónico (Clásico)',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (state.contacts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index.isOdd) return const SizedBox(height: 12);
                          
                          final contactIndex = index ~/ 2;
                          final contact = state.contacts[contactIndex];
                          return _ContactCard(
                            contact: contact,
                            onEdit: () => _showContactDialog(context, contact: contact),
                            onDelete: () => _confirmDelete(context, contact),
                          );
                        },
                        childCount: state.contacts.length * 2 - 1,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDigitalGuardianSection(BuildContext context, WidgetRef ref) {
    final guardianState = ref.watch(patientGuardiansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Familiar Conectado (AsthmaApp)',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Permite que un familiar monitoree tu asma en tiempo real desde su propia app.',
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBCE3F9)),
          ),
          child: guardianState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : guardianState.guardians.isEmpty
                  ? _buildLinkingCode(context, guardianState.linkingCode)
                  : _buildGuardianList(context, ref, guardianState.guardians),
        ),
      ],
    );
  }

  Widget _buildLinkingCode(BuildContext context, String? code) {
    if (code == null) return const Center(child: Text('Error cargando código'));

    return Column(
      children: [
        const Text(
          'Tu Código de Vinculación',
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF023E8A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código copiado al portapapeles')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar Código'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF023E8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuardianList(
      BuildContext context, WidgetRef ref, List<Map<String, dynamic>> guardians) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFF023E8A)),
            const SizedBox(width: 8),
            const Text(
              'Guardianes Activos',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF023E8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...guardians.map((g) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF023E8A).withOpacity(0.1),
                  child: Text(
                    g['full_name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF023E8A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['full_name'],
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        g['email'],
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('¿Desvincular guardián?'),
                        content: Text('Dejará de tener acceso a tus alertas.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ref
                                  .read(patientGuardiansProvider.notifier)
                                  .unlinkGuardian(g['id']);
                            },
                            child: const Text('Desvincular',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  tooltip: 'Desvincular',
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF023E8A).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.contacts_outlined,
              size: 56,
              color: Color(0xFF023E8A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin contactos de emergencia',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega un contacto para que puedan\nser notificados en caso de emergencia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContactDialog(
    BuildContext context, {
    EmergencyContactModel? contact,
  }) async {
    final nameCtrl = TextEditingController(text: contact?.contactName ?? '');
    final phoneCtrl = TextEditingController(text: contact?.phoneNumber ?? '');
    final relCtrl = TextEditingController(text: contact?.relationship ?? '');
    bool isPrimary = contact?.isPrimary ?? false;

    final nameFocus = FocusNode();
    bool showNameError = false;

    final phoneFocus = FocusNode();
    bool showPhoneError = false;

    final relFocus = FocusNode();
    bool showRelError = false;

    StateSetter? localSetState;

    nameFocus.addListener(() {
      if (!nameFocus.hasFocus) {
        localSetState?.call(() => showNameError = nameCtrl.text.trim().isEmpty);
      } else {
        localSetState?.call(() => showNameError = false);
      }
    });

    phoneFocus.addListener(() {
      if (!phoneFocus.hasFocus) {
        localSetState?.call(
          () => showPhoneError = phoneCtrl.text.trim().length < 10,
        );
      } else {
        localSetState?.call(() => showPhoneError = false);
      }
    });

    relFocus.addListener(() {
      if (!relFocus.hasFocus) {
        localSetState?.call(() => showRelError = relCtrl.text.trim().isEmpty);
      } else {
        localSetState?.call(() => showRelError = false);
      }
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          localSetState = setSheetState;
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    contact == null ? 'Nuevo Contacto' : 'Editar Contacto',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    nameCtrl,
                    'Nombre completo',
                    Icons.person_outline,
                    maxLength: 25,
                    focusNode: nameFocus,
                    errorText: showNameError
                        ? 'El nombre es obligatorio'
                        : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    phoneCtrl,
                    'Teléfono (10 dígitos)',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    focusNode: phoneFocus,
                    errorText: showPhoneError ? 'Debe tener 10 dígitos' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    relCtrl,
                    'Parentesco (ej. Madre, Esposo)',
                    Icons.family_restroom_outlined,
                    maxLength: 20,
                    focusNode: relFocus,
                    errorText: showRelError
                        ? 'El parentesco es obligatorio'
                        : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Toggle primario
                  GestureDetector(
                    onTap: () => setSheetState(() => isPrimary = !isPrimary),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? const Color(0xFF023E8A).withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPrimary
                              ? const Color(0xFF023E8A)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPrimary ? Icons.star_rounded : Icons.star_outline,
                            color: isPrimary
                                ? const Color(0xFF023E8A)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Contacto principal',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Switch(
                            value: isPrimary,
                            onChanged: (v) =>
                                setSheetState(() => isPrimary = v),
                            activeColor: const Color(0xFF023E8A),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isPrimary)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 4,
                        right: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Al guardar, este contacto reemplazará a tu contacto principal actual.',
                              style: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 13,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: Listenable.merge([nameCtrl, phoneCtrl, relCtrl]),
                    builder: (context, _) {
                      final bool isValid =
                          nameCtrl.text.trim().isNotEmpty &&
                          phoneCtrl.text.trim().length >= 10 &&
                          relCtrl.text.trim().isNotEmpty;

                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isValid
                              ? () async {
                                  Navigator.pop(context);
                                  if (contact == null) {
                                    await ref
                                        .read(
                                          emergencyContactsProvider.notifier,
                                        )
                                        .createContact(
                                          name: nameCtrl.text.trim(),
                                          phone: phoneCtrl.text.trim(),
                                          relationship: relCtrl.text.trim(),
                                          isPrimary: isPrimary,
                                        );
                                  } else {
                                    await ref
                                        .read(
                                          emergencyContactsProvider.notifier,
                                        )
                                        .updateContact(
                                          contactId: contact.id,
                                          name: nameCtrl.text.trim(),
                                          phone: phoneCtrl.text.trim(),
                                          relationship: relCtrl.text.trim(),
                                          isPrimary: isPrimary,
                                        );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF023E8A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            contact == null ? 'Guardar Contacto' : 'Actualizar',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    nameFocus.dispose();
    phoneFocus.dispose();
    relFocus.dispose();
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    String? errorText,
  }) {
    return TextField(
      controller: ctrl,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontFamily: 'GeneralSans', fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        errorText: errorText,
        prefixIcon: Icon(icon, color: const Color(0xFF023E8A), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF023E8A), width: 1.5),
        ),
        counterText: '',
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar contacto?',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Se eliminará a ${contact.contactName} de tus contactos de emergencia.',
          style: const TextStyle(fontFamily: 'GeneralSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(emergencyContactsProvider.notifier)
                  .deleteContact(contact.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white, fontFamily: 'Satoshi'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Card Widget ──────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contact.isPrimary
              ? const Color(0xFF023E8A).withOpacity(0.3)
              : Colors.grey.shade200,
          width: contact.isPrimary ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF023E8A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.contactName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF023E8A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.contactName,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF023E8A),
                        size: 16,
                      ),
                    ],
                  ],
                ),
                if (contact.relationship != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    contact.relationship!,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contact.phoneNumber,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Acciones
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF023E8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF023E8A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
