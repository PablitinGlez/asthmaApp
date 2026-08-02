import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-set-password',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './set-password.component.html'
})
export class SetPasswordComponent {
  private authService = inject(AuthService);
  private router = inject(Router);

  password = '';
  confirmPassword = '';
  isLoading = false;
  message = '';
  isError = false;
  isPatientSuccess = false;

  async onSubmit() {
    if (this.password !== this.confirmPassword) {
      this.isError = true;
      this.message = 'Las contraseñas no coinciden.';
      return;
    }

    if (this.password.length < 6) {
      this.isError = true;
      this.message = 'La contraseña debe tener al menos 6 caracteres.';
      return;
    }

    this.isLoading = true;
    this.message = '';
    
    try {
      await this.authService.updatePassword(this.password);
      console.log(' Contraseña actualizada correctamente');
      
      
      const user = this.authService.currentUserValue;
      let role = 'patient';
      if (user) {
        try {
          const rolePromise = this.authService.getUserRole(user.id);
          const timeoutPromise = new Promise<null>(resolve => setTimeout(() => resolve(null), 3000));
          const result = await Promise.race([rolePromise, timeoutPromise]);
          role = result || 'patient';
          console.log(' Rol detectado:', role);
        } catch (roleErr) {
          console.warn('No se pudo obtener el rol, asumiendo paciente:', roleErr);
          role = 'patient';
        }
      }

      if (role === 'doctor' || role === 'admin') {
        this.isError = false;
        this.message = '¡Contraseña creada con éxito! Redirigiendo al Dashboard...';
        setTimeout(() => {
          this.router.navigate(['/dashboard']);
        }, 2000);
      } else {
        
        this.isPatientSuccess = true;
        this.isError = false;
        this.message = '¡Cuenta activada! Ya puedes ingresar a la app con tu email y contraseña.';
      }
    } catch (e: any) {
      this.isError = true;
      this.message = 'Error al crear la contraseña: ' + (e.message || 'Error desconocido');
      console.error('Error en set-password:', e);
    } finally {
      this.isLoading = false;
    }
  }
}
