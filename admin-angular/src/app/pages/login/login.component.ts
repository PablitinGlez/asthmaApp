import { Component, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html'
})
export class LoginComponent {
  email = '';
  password = '';
  showPassword = false;
  error: string | null = null;
  isLoading = false;

  constructor(
    private authService: AuthService, 
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  togglePassword() {
    this.showPassword = !this.showPassword;
  }

  async onLogin() {
    this.error = null;
    this.isLoading = true;
    this.cdr.detectChanges();
    
    try {
      const { user } = await this.authService.login(this.email, this.password);
      
      if (user) {
        
        this.router.navigate(['/dashboard']);
      }
    } catch (err: any) {
      this.error = 'Credenciales inválidas o error de conexión.';
      console.error(err);
      this.cdr.detectChanges();
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
    }
  }
}
