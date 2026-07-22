import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { DoctorService } from '../../services/doctor.service';
import { Router } from '@angular/router';
import { SidebarComponent } from '../../components/sidebar/sidebar.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, SidebarComponent],
  templateUrl: './dashboard.component.html'
})
export class DashboardComponent implements OnInit {
  private authService = inject(AuthService);
  private doctorService = inject(DoctorService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);
  
  user$ = this.authService.currentUser$;
  role$ = this.authService.currentUserRole$;

  doctorProfile: any = null;

  ngOnInit() {
    this.role$.subscribe(role => {
      if (role === 'doctor') {
        this.loadDoctorProfile();
      }
    });
  }

  async loadDoctorProfile() {
    try {
      this.doctorProfile = await this.doctorService.getMyProfile();
      this.cdr.detectChanges();
    } catch (e) {
      console.error('Error cargando perfil del doctor:', e);
    }
  }

  async onLogout() {
    await this.authService.logout();
    this.router.navigate(['/login']);
  }
}
