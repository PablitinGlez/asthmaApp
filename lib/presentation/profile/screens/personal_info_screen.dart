import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/personal_info_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _pefCtrl;

  late TextEditingController _addressStreetCtrl;
  late TextEditingController _addressCityCtrl;
  late TextEditingController _addressStateCtrl;
  late TextEditingController _addressZipCtrl;
  late TextEditingController _insuranceCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _diagnosisDateCtrl;
  late TextEditingController _allergiesCtrl;

  
  late FocusNode _firstNameNode;
  late FocusNode _lastNameNode;
  late FocusNode _phoneNode;
  late FocusNode _ageNode;
  late FocusNode _heightNode;
  late FocusNode _weightNode;
  late FocusNode _pefNode;
  late FocusNode _cityNode;
  late FocusNode _stateNode;
  late FocusNode _zipNode;

  
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _ageError;
  String? _heightError;
  String? _weightError;
  String? _pefError;
  String? _cityError;
  String? _stateError;
  String? _zipError;

  String? _selectedGender;
  String? _selectedBloodType;
  String? _selectedAsthmaType;

  bool _initialized = false;
  bool _isFormValid = true;
  bool _isEditing = false; 
  bool _isDirty = false; 

  @override
  void initState() {
    super.initState();
    
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _pefCtrl = TextEditingController();

    _addressStreetCtrl = TextEditingController();
    _addressCityCtrl = TextEditingController();
    _addressStateCtrl = TextEditingController();
    _addressZipCtrl = TextEditingController();
    _insuranceCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _diagnosisDateCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();

    _firstNameNode = FocusNode();
    _lastNameNode = FocusNode();
    _phoneNode = FocusNode();
    _ageNode = FocusNode();
    _heightNode = FocusNode();
    _weightNode = FocusNode();
    _pefNode = FocusNode();
    _cityNode = FocusNode();
    _stateNode = FocusNode();
    _zipNode = FocusNode();

    
    _setupFocusValidation(
      _firstNameNode,
      _firstNameCtrl,
      _validateName,
      (e) => _firstNameError = e,
    );
    _setupFocusValidation(
      _lastNameNode,
      _lastNameCtrl,
      _validateOptionalName,
      (e) => _lastNameError = e,
    );
    _setupFocusValidation(
      _phoneNode,
      _phoneCtrl,
      _validatePhone,
      (e) => _phoneError = e,
    );
    _setupFocusValidation(
      _ageNode,
      _ageCtrl,
      _validateAge,
      (e) => _ageError = e,
    );
    _setupFocusValidation(
      _heightNode,
      _heightCtrl,
      _validateOptionalNumber,
      (e) => _heightError = e,
    );
    _setupFocusValidation(
      _weightNode,
      _weightCtrl,
      _validateOptionalNumber,
      (e) => _weightError = e,
    );
    _setupFocusValidation(
      _pefNode,
      _pefCtrl,
      _validateOptionalNumber,
      (e) => _pefError = e,
    );
    _setupFocusValidation(
      _cityNode,
      _addressCityCtrl,
      _validateOptionalName,
      (e) => _cityError = e,
    );
    _setupFocusValidation(
      _stateNode,
      _addressStateCtrl,
      _validateOptionalName,
      (e) => _stateError = e,
    );
    _setupFocusValidation(
      _zipNode,
      _addressZipCtrl,
      _validateZip,
      (e) => _zipError = e,
    );

    
    for (final ctrl in [
      _firstNameCtrl,
      _lastNameCtrl,
      _phoneCtrl,
      _ageCtrl,
      _heightCtrl,
      _weightCtrl,
      _pefCtrl,
      _addressStreetCtrl,
      _addressCityCtrl,
      _addressStateCtrl,
      _addressZipCtrl,
      _insuranceCtrl,
      _diagnosisDateCtrl,
      _allergiesCtrl,
    ]) {
      ctrl.addListener(() {
        if (!_isDirty && _isEditing) setState(() => _isDirty = true);
        _validateAll();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _validateAll());
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _pefCtrl.dispose();
    _addressStreetCtrl.dispose();
    _addressCityCtrl.dispose();
    _addressStateCtrl.dispose();
    _addressZipCtrl.dispose();
    _insuranceCtrl.dispose();
    _weightCtrl.dispose();
    _diagnosisDateCtrl.dispose();
    _allergiesCtrl.dispose();

    _firstNameNode.dispose();
    _lastNameNode.dispose();
    _phoneNode.dispose();
    _ageNode.dispose();
    _heightNode.dispose();
    _weightNode.dispose();
    _pefNode.dispose();
    _cityNode.dispose();
    _stateNode.dispose();
    _zipNode.dispose();
    super.dispose();
  }

  
  void _setupFocusValidation(
    FocusNode node,
    TextEditingController ctrl,
    String? Function(String?) validator,
    void Function(String?) setError,
  ) {
    node.addListener(() {
      if (!node.hasFocus) {
        setState(() {
          setError(validator(ctrl.text));
        });
        _validateAll();
      }
    });
  }

  void _validateAll() {
    if (!_isEditing) return; 
    bool valid = true;

    final nameErr = _validateName(_firstNameCtrl.text);
    if (nameErr != null) valid = false;

    final lastErr = _validateOptionalName(_lastNameCtrl.text);
    if (lastErr != null) valid = false;

    final phoneErr = _phoneCtrl.text.isNotEmpty ? _validatePhone(_phoneCtrl.text) : null;
    if (phoneErr != null) valid = false;

    final ageErr = _ageCtrl.text.isNotEmpty ? _validateAge(_ageCtrl.text) : null;
    if (ageErr != null) valid = false;

    final heightErr = _heightCtrl.text.isNotEmpty ? _validateOptionalNumber(_heightCtrl.text) : null;
    if (heightErr != null) valid = false;

    final weightErr = _weightCtrl.text.isNotEmpty ? _validateOptionalNumber(_weightCtrl.text) : null;
    if (weightErr != null) valid = false;

    final pefErr = _pefCtrl.text.isNotEmpty ? _validateOptionalNumber(_pefCtrl.text) : null;
    if (pefErr != null) valid = false;

    final cityErr = _addressCityCtrl.text.isNotEmpty ? _validateOptionalName(_addressCityCtrl.text) : null;
    if (cityErr != null) valid = false;

    final stateErr = _addressStateCtrl.text.isNotEmpty ? _validateOptionalName(_addressStateCtrl.text) : null;
    if (stateErr != null) valid = false;

    final zipErr = _addressZipCtrl.text.isNotEmpty ? _validateZip(_addressZipCtrl.text) : null;
    if (zipErr != null) valid = false;

    
    if (_firstNameError != nameErr) _firstNameError = nameErr;
    if (_lastNameError != lastErr) _lastNameError = lastErr;
    if (_phoneError != phoneErr) _phoneError = phoneErr;
    if (_ageError != ageErr) _ageError = ageErr;
    if (_heightError != heightErr) _heightError = heightErr;
    if (_weightError != weightErr) _weightError = weightErr;
    if (_pefError != pefErr) _pefError = pefErr;
    if (_cityError != cityErr) _cityError = cityErr;
    if (_stateError != stateErr) _stateError = stateErr;
    if (_zipError != zipErr) _zipError = zipErr;

    if (_isFormValid != valid) {
      if (mounted) setState(() => _isFormValid = valid);
    }
  }

  String? _validateZip(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    if (val.length < 5) return 'Mínimo 5 dígitos';
    return null;
  }

  
  String? _validateName(String? val) {
    if (val == null || val.trim().isEmpty) return 'Campo requerido';
    if (val.trim().length > 50) return 'Máximo 50 caracteres';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(val)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  String? _validatePhone(String? val) {
    
    if (val == null || val.trim().isEmpty) return null;
    if (val.replaceAll(RegExp(r'\D'), '').length != 10)
      return 'Debe tener 10 dígitos';
    return null;
  }

  String? _validateAge(String? val) {
    if (val == null || val.trim().isEmpty) return null; 
    final age = int.tryParse(val);
    if (age == null || age <= 0 || age > 130) return 'Edad inválida (1-130)';
    return null;
  }

  String? _validateOptionalNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final n = double.tryParse(val);
    if (n == null || n <= 0) return 'Número inválido';
    return null;
  }

  String? _validateOptionalName(String? val) {
    if (val == null || val.trim().isEmpty) return null; 
    if (val.trim().length > 50) return 'Máximo 50 caracteres';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(val)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  void _initFields(profile) {
    if (_initialized) return;

    if (profile != null) {
      
      _firstNameCtrl.text = profile.firstName ?? '';
      
      _lastNameCtrl.text = profile.lastName ?? '';

      _ageCtrl.text = profile.age?.toString() ?? '';
      _phoneCtrl.text = profile.phoneNumber ?? '';
      _heightCtrl.text = profile.heightCm?.toString() ?? '';
      _pefCtrl.text = profile.personalBestPef?.toString() ?? '';
      _weightCtrl.text = profile.weightKg?.toString() ?? '';
      _addressStreetCtrl.text = profile.addressStreet ?? '';
      _addressCityCtrl.text = profile.addressCity ?? '';
      _addressStateCtrl.text = profile.addressState ?? '';
      _addressZipCtrl.text = profile.addressZip ?? '';
      _insuranceCtrl.text = profile.healthInsuranceNumber ?? '';
      _diagnosisDateCtrl.text = profile.diagnosisDate ?? '';
      _allergiesCtrl.text = profile.knownAllergies ?? '';

      final g = profile.gender;
      if (g == 'male' || g == 'Masculino')
        _selectedGender = 'Masculino';
      else if (g == 'female' || g == 'Femenino')
        _selectedGender = 'Femenino';
      else if (g != null)
        _selectedGender = 'Otro';

      final allowedBlood = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      _selectedBloodType = allowedBlood.contains(profile.bloodType)
          ? profile.bloodType
          : null;

      final allowedAsthma = [
        'Intermitente',
        'Persistente Leve',
        'Persistente Moderada',
        'Persistente Grave',
      ];
      _selectedAsthmaType = allowedAsthma.contains(profile.asthmaType)
          ? profile.asthmaType
          : null;
    }

    
    
    if (_firstNameCtrl.text.isEmpty) {
      final fullName = ref.read(authStateProvider).value?.fullName.trim() ?? '';
      if (fullName.isNotEmpty) {
        final spaceIdx = fullName.indexOf(' ');
        if (spaceIdx == -1) {
          _firstNameCtrl.text = fullName;
        } else {
          _firstNameCtrl.text = fullName.substring(0, spaceIdx);
          _lastNameCtrl.text = fullName.substring(spaceIdx + 1);
        }
        _isDirty = true; 
      }
    }

    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateAll());
  }

  Future<void> _saveOriginalChanges() async {
    if (!_isFormValid) return;

    
    if (!_isDirty) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    final data = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim().isEmpty
          ? null
          : _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim().isEmpty
          ? null
          : _lastNameCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text),
      'gender': _selectedGender,
      'phone_number': _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      'address_street': _addressStreetCtrl.text.trim().isEmpty
          ? null
          : _addressStreetCtrl.text.trim(),
      'address_city': _addressCityCtrl.text.trim().isEmpty
          ? null
          : _addressCityCtrl.text.trim(),
      'address_state': _addressStateCtrl.text.trim().isEmpty
          ? null
          : _addressStateCtrl.text.trim(),
      'address_zip': _addressZipCtrl.text.trim().isEmpty
          ? null
          : _addressZipCtrl.text.trim(),
      'health_insurance_number': _insuranceCtrl.text.trim().isEmpty
          ? null
          : _insuranceCtrl.text.trim(),
      
      'height_cm': double.tryParse(_heightCtrl.text),
      'weight_kg': double.tryParse(_weightCtrl.text),
      'blood_type': _selectedBloodType,
      'personal_best_pef': int.tryParse(_pefCtrl.text),
      'asthma_type': _selectedAsthmaType,
      'diagnosis_date': _diagnosisDateCtrl.text.trim().isEmpty
          ? null
          : _diagnosisDateCtrl.text.trim(),
      'known_allergies': _allergiesCtrl.text.trim().isEmpty
          ? null
          : _allergiesCtrl.text.trim(),
    };

    data.removeWhere((key, value) => value == null);

    final success = await ref
        .read(personalInfoProvider.notifier)
        .updateProfile(data);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
        _isDirty = false;
      }); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente.')),
      );
    } else if (mounted) {
      final error = ref.read(personalInfoProvider).errorMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalInfoProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF023E8A)),
        ),
      );
    }

    _initFields(state.profile);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text(
            'Perfil de Salud',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFamily: 'Satoshi',
            ),
          ),
          backgroundColor: const Color(0xFF023E8A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderBanner(), 

              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: Color(0xFF023E8A),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF023E8A),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(text: 'Info. Personal'),
                    Tab(text: 'Historial Médico'),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [_buildPersonalTab(), _buildMedicalTab()],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: state.isSaving
              ? null
              : () {
                  if (_isEditing) {
                    if (_isFormValid) _saveOriginalChanges();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
          backgroundColor: _isEditing && !_isFormValid
              ? Colors.grey.shade400
              : const Color(0xFF023E8A),
          icon: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                  color: Colors.white,
                ),
          label: Text(
            state.isSaving
                ? 'Guardando...'
                : (_isEditing ? 'Guardar' : 'Editar'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Satoshi',
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildHeaderBanner() {
    final user = ref.watch(authStateProvider).value;
    return Container(
      width: double.infinity,
      color: const Color(0xFF023E8A),
      
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          
          Positioned(
            right: -20,
            top: -40,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(
                Icons.health_and_safety,
                size: 160,
                color: Colors.white,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: 30,
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SvgPicture.network(
                      'https://api.dicebear.com/9.x/initials/svg?seed=${user?.fullName ?? 'Usuario'}&backgroundColor=${user?.avatarBackground ?? '023e8a'}',
                      fit: BoxFit.cover,
                      placeholderBuilder: (context) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        
                        (ref.watch(authStateProvider).value?.fullName ??
                                'Paciente')
                            .trim()
                            .split(RegExp(r'\s+'))
                            .first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Satoshi',
                          fontSize: 24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Paciente Activo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildPersonalTab() {
    final profile = ref.watch(personalInfoProvider).profile;
    final hasMedicalData =
        profile != null &&
        (profile.heightCm != null ||
            profile.asthmaType != null ||
            profile.bloodType != null ||
            profile.personalBestPef != null);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          
          if (!hasMedicalData) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD600), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF9A825),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Completa tus datos médicos en la pestaña "Historial Médico"!',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildCardWrapper(
            title: 'Datos Personales',
            children: [
              
              _buildTextField(
                controller: _firstNameCtrl,
                label: 'Nombre',
                focusNode: _firstNameNode,
                errorText: _firstNameError,
                maxLength: 50,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _lastNameCtrl,
                label: 'Apellido',
                focusNode: _lastNameNode,
                errorText: _lastNameError,
                maxLength: 50,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Teléfono',
                keyboardType: TextInputType.phone,
                focusNode: _phoneNode,
                errorText: _phoneError,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageCtrl,
                      label: 'Edad',
                      keyboardType: TextInputType.number,
                      focusNode: _ageNode,
                      errorText: _ageError,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedGender,
                      label: 'Género',
                      items: ['Masculino', 'Femenino', 'Otro'],
                      onChanged: (val) {
                        setState(() {
                          _selectedGender = val;
                          if (_isEditing) _isDirty = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardWrapper(
            title: 'Domicilio',
            children: [
              _buildTextField(
                controller: _addressStreetCtrl,
                label: 'Calle / Avenida',
                keyboardType: TextInputType.streetAddress,
                maxLength: 120,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressCityCtrl,
                label: 'Ciudad',
                maxLength: 50,
                focusNode: _cityNode,
                errorText: _cityError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressStateCtrl,
                label: 'Estado',
                maxLength: 50,
                focusNode: _stateNode,
                errorText: _stateError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressZipCtrl,
                label: 'Código Postal',
                keyboardType: TextInputType.number,
                focusNode: _zipNode,
                errorText: _zipError,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardWrapper(
            title: 'Información de Seguro',
            children: [
              _buildTextField(
                controller: _insuranceCtrl,
                label: 'Seguro Médico / NSS',
                maxLength: 30,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  
  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCardWrapper(
            title: 'Físico y Vitales',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _weightCtrl,
                      label: 'Peso (Kg)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      focusNode: _weightNode,
                      errorText: _weightError,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'),
                        ),
                        LengthLimitingTextInputFormatter(5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightCtrl,
                      label: 'Altura (cm)',
                      keyboardType: TextInputType.number,
                      focusNode: _heightNode,
                      errorText: _heightError,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ], 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                value: _selectedBloodType,
                label: 'Tipo de Sangre',
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                onChanged: (val) {
                  setState(() {
                    _selectedBloodType = val;
                    if (_isEditing) _isDirty = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardWrapper(
            title: 'Cuadro Respiratorio',
            children: [
              _buildDropdownField(
                value: _selectedAsthmaType,
                label: 'Tipo de Asma',
                items: [
                  'Intermitente',
                  'Persistente Leve',
                  'Persistente Moderada',
                  'Persistente Grave',
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedAsthmaType = val;
                    if (_isEditing) _isDirty = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _diagnosisDateCtrl,
                label: 'Fecha de Diagnóstico',
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _diagnosisDateCtrl.text =
                          "${picked.day}/${picked.month}/${picked.year}";
                      if (_isEditing) _isDirty = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pefCtrl,
                label: 'Mejor PEF Personal (L/min)',
                keyboardType: TextInputType.number,
                focusNode: _pefNode,
                errorText: _pefError,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ], 
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardWrapper(
            title: 'Tratamientos y Riesgos',
            children: [
              _buildTextField(
                controller: _allergiesCtrl,
                label: 'Alergias Conocidas',
                maxLines: 2,
                maxLength: 300,
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  
  Widget _buildCardWrapper({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    FocusNode? focusNode,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isReadOnly = readOnly || !_isEditing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ...?inputFormatters,
          ],
          maxLines: maxLines,
          readOnly: isReadOnly,
          onTap: onTap,
          style: const TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          decoration: InputDecoration(
            errorText: _isEditing
                ? errorText
                : null, 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            filled: true,
            fillColor: isReadOnly
                ? const Color(0xFFF0F0F0)
                : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorStyle: const TextStyle(
              fontFamily: 'GeneralSans',
              fontWeight: FontWeight.normal, 
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _isEditing ? onChanged : null,
          icon: Icon(Icons.expand_more_rounded, color: _isEditing ? Colors.grey : Colors.transparent),
          style: const TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.normal,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: _isEditing ? Colors.grey.shade100 : const Color(0xFFF0F0F0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
