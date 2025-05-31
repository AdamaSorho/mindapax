import { Component } from '@angular/core';
import { PrimaryLayoutComponent } from '../@theme/layouts/primary-layout/primary-layout.component';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-auth',
  imports: [PrimaryLayoutComponent, RouterOutlet],
  templateUrl: './auth.component.html',
  styleUrl: './auth.component.css',
})
export class AuthComponent {}
