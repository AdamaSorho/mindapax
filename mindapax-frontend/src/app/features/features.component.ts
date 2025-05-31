import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MemberPrimaryLayoutComponent } from '../@theme/layouts/member-primary-layout/member-primary-layout.component';

@Component({
  selector: 'app-features',
  imports: [RouterOutlet, MemberPrimaryLayoutComponent],
  templateUrl: './features.component.html',
  styleUrl: './features.component.css',
})
export class FeaturesComponent {}
