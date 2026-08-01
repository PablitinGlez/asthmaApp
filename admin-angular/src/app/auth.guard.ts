import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './services/auth.service';
import { map, take } from 'rxjs';

export const authGuard: CanActivateFn = async (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  // Interceptar invitaciones de Supabase (Hash Check)
  const hash = window.location.hash;
  if (hash && hash.includes('type=invite')) {
    console.log('Invitación detectada en authGuard, redirigiendo a set-password...');
    router.navigate(['/set-password'], { fragment: hash.substring(1) });
    return false;
  }

  // Comprobación de sesión real (esperando a Supabase)
  const user = await authService.getSession();
  
  if (!user) {
    router.navigate(['/login']);
    return false;
  }

  // Verificación de Roles
  const requiredRole = route.data?.['role'];
  if (requiredRole) {
    // Si la ruta requiere un rol (ej. 'admin'), esperamos que el rol esté cargado
    // Suscribirse temporalmente para obtener el valor más reciente del BehaviorSubject
    let currentRole = null;
    authService.currentUserRole$.pipe(take(1)).subscribe(role => currentRole = role);

    if (currentRole !== requiredRole) {
      console.warn(`Acceso denegado: Se requiere rol ${requiredRole}, tienes rol ${currentRole}`);
      router.navigate(['/dashboard']);
      return false;
    }
  }

  return true;
};
