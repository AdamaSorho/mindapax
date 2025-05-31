import { Component } from '@angular/core';
import { PrimaryLayoutComponent } from '../@theme/layouts/primary-layout/primary-layout.component';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-pages',
  imports: [PrimaryLayoutComponent, RouterOutlet],
  templateUrl: './pages.component.html',
  styleUrl: './pages.component.css',
})
export class PagesComponent {}
