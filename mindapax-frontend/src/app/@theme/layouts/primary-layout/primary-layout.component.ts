import { Component } from '@angular/core';
import { FooterComponent } from '../../components/footer/footer.component';
import { HeaderComponent } from '../../components/header/header.component';

@Component({
  selector: 'app-primary-layout',
  imports: [FooterComponent, HeaderComponent],
  templateUrl: './primary-layout.component.html',
  styleUrl: './primary-layout.component.css',
})
export class PrimaryLayoutComponent {}
