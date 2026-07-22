import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { AdminService } from '../../services/admin.service';
import { SidebarComponent } from '../../components/sidebar/sidebar.component';

@Component({
  selector: 'app-doctors',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, RouterLinkActive, SidebarComponent],
  templateUrl: './doctors.component.html',
  styleUrl: './doctors.component.css'
})
export class DoctorsComponent implements OnInit {
  private adminService = inject(AdminService);
  private cdr = inject(ChangeDetectorRef);
  
  doctors: any[] = [];
  showModal = false;
  isLoading = false;
  isError = false;

  // Detalles del doctor (Panel Lateral)
  selectedDoctor: any = null;
  showDetailsPanel = false;

  // Toast state
  showToast = false;
  toastMessage = '';
  toastType: 'success' | 'error' = 'success';

  // Form data
  newDoctor = {
    email: '',
    full_name: '',
    specialty: '',
    license_number: '',
    hospital_name: '',
    bio: ''
  };

  ngOnInit() {
    this.loadDoctors();
  }

  openModal() {
    this.showModal = true;
    this.isError = false;
  }

  openDetails(doctor: any) {
    this.selectedDoctor = doctor;
    this.showDetailsPanel = true;
  }

  closeDetails() {
    this.showDetailsPanel = false;
    setTimeout(() => this.selectedDoctor = null, 300); // Esperar a que termine la animación
  }

  async loadDoctors() {
    try {
      this.doctors = await this.adminService.getDoctors();
      this.cdr.detectChanges(); // Forzar actualización visual tras cargar
    } catch (e) {
      console.error('Error loading doctors:', e);
    }
  }

  async onInvite() {
    console.log('[DEBUG] 1. onInvite llamado. Iniciando carga...');
    this.isLoading = true;
    this.isError = false;
    this.cdr.detectChanges();

    try {
      console.log('[DEBUG] 2. Llamando a adminService.inviteDoctor...');
      const response = await this.adminService.inviteDoctor(this.newDoctor);
      console.log('[DEBUG] 3. Invitación exitosa (Respuesta API 200 OK):', response);
      
      // Cerramos de inmediato el modal
      this.showModal = false;
      console.log('[DEBUG] 4. showModal establecido a false');
      
      // Disparamos el Toast
      this.toastMessage = '¡Invitación enviada con éxito!';
      this.toastType = 'success';
      this.showToast = true;
      console.log('[DEBUG] 5. Toast configurado para mostrarse');
      
      // Forzar a Angular a dibujar los cambios Inmediatamente
      this.cdr.detectChanges();
      console.log('[DEBUG] 6. detectChanges() ejecutado para forzar cierre del modal en la UI');

      this.loadDoctors(); 
      console.log('[DEBUG] 7. loadDoctors() lanzado en segundo plano');
      
      // Ocultar toast después de 3s
      setTimeout(() => {
        this.showToast = false;
        this.cdr.detectChanges();
        console.log('[DEBUG] 8. Toast ocultado después de 3 segundos');
      }, 3000);

      // Reset form
      this.newDoctor = { email: '', full_name: '', specialty: '', license_number: '', hospital_name: '', bio: '' };
    } catch (e: any) {
      console.log('[DEBUG] Error atrapado en onInvite:', e);
      this.isError = true;
      this.toastMessage = 'Error: ' + (e.error?.detail || 'No se pudo enviar la invitación');
      this.toastType = 'error';
      this.showToast = true;
      this.cdr.detectChanges(); // Forzar dibujo del error en UI
      setTimeout(() => {
        this.showToast = false;
        this.cdr.detectChanges();
      }, 4000);
      console.error(e);
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
      console.log('[DEBUG] 9. Finalizado onInvite (finally block)');
    }
  }
}
