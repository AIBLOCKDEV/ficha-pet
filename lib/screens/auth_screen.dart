import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  String _selectedRole = 'owner'; // 'owner' | 'vet'
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _clinicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isLogin) {
        await auth.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text,
          role: _selectedRole,
          clinicName: _selectedRole == 'vet' ? _clinicController.text : '',
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(msg),
        ),
      );
    }
  }

  Future<void> _enterDemo({required bool asVet}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (asVet) {
        await auth.loginDemoVet();
      } else {
        await auth.loginDemo();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar demo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.45),
              scheme.surface,
              scheme.secondaryContainer.withValues(alpha: 0.35),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo oficial Ficha + Pet restaurado en alta definición
                    Container(
                      width: 164,
                      height: 164,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.14),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.pets_rounded,
                          size: 64,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Ficha Pet',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Salud clínica, recordatorios push e historial de tus mascotas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta Material You de Login / Registro
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: true,
                                    icon: Icon(Icons.login_rounded),
                                    label: Text('Iniciar sesión'),
                                  ),
                                  ButtonSegment<bool>(
                                    value: false,
                                    icon: Icon(Icons.person_add_alt_1_rounded),
                                    label: Text('Registrarse'),
                                  ),
                                ],
                                selected: {_isLogin},
                                onSelectionChanged: (set) {
                                  setState(() => _isLogin = set.first);
                                },
                              ),
                              const SizedBox(height: 22),

                              if (!_isLogin) ...[
                                Text(
                                  'Tipo de cuenta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment<String>(
                                      value: 'owner',
                                      icon: Icon(Icons.pets_rounded),
                                      label: Text('Dueño'),
                                    ),
                                    ButtonSegment<String>(
                                      value: 'vet',
                                      icon:
                                          Icon(Icons.medical_services_rounded),
                                      label: Text('Veterinario'),
                                    ),
                                  ],
                                  selected: {_selectedRole},
                                  onSelectionChanged: (set) {
                                    setState(() => _selectedRole = set.first);
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: _selectedRole == 'vet'
                                        ? 'Nombre del Veterinario'
                                        : 'Nombre completo',
                                    prefixIcon: const Icon(Icons.badge_rounded),
                                  ),
                                  validator: (v) {
                                    if (!_isLogin &&
                                        (v == null || v.trim().length < 2)) {
                                      return 'Ingresa tu nombre';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                if (_selectedRole == 'vet') ...[
                                  TextFormField(
                                    controller: _clinicController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Clínica o Consultorio (opcional)',
                                      prefixIcon:
                                          Icon(Icons.local_hospital_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ],

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon:
                                      Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (v) {
                                  if (v == null ||
                                      !v.contains('@') ||
                                      !v.contains('.')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono (opcional)',
                                    prefixIcon: Icon(Icons.call_rounded),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().length < 4) {
                                    return 'Mínimo 4 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),

                              FilledButton.icon(
                                onPressed: auth.isBusy ? null : _submit,
                                icon: auth.isBusy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Icon(_isLogin
                                        ? Icons.arrow_forward_rounded
                                        : Icons.how_to_reg_rounded),
                                label: Text(_isLogin
                                    ? 'Entrar a mi cuenta'
                                    : 'Crear cuenta y entrar'),
                              ),
                              const SizedBox(height: 12),

                              FilledButton.tonalIcon(
                                onPressed: auth.isBusy
                                    ? null
                                    : () => _enterDemo(asVet: false),
                                icon: const Icon(Icons.pets_rounded),
                                label: const Text(
                                    'Acceso rápido · Dueño (Demo)'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: auth.isBusy
                                    ? null
                                    : () => _enterDemo(asVet: true),
                                icon: const Icon(
                                    Icons.medical_services_rounded),
                                label: const Text(
                                    'Acceso rápido · Veterinario (Demo)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chips informativos Material You
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(
                          avatar: Icon(Icons.notifications_active_rounded,
                              size: 16, color: scheme.primary),
                          label: const Text(
                            'Alertas cada 2 días en vacunas vencidas',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Chip(
                          avatar: Icon(Icons.verified_user_rounded,
                              size: 16, color: scheme.primary),
                          label: const Text(
                            'Perfil individual por usuario',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
