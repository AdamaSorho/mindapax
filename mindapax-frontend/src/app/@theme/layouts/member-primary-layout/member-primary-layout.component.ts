import { Component } from '@angular/core';
import { MemberSidebarComponent } from '../../components/member-sidebar/member-sidebar.component';
import { MemberHeaderComponent } from '../../components/member-header/member-header.component';

@Component({
  selector: 'app-member-primary-layout',
  imports: [MemberSidebarComponent, MemberHeaderComponent],
  templateUrl: './member-primary-layout.component.html',
  styleUrl: './member-primary-layout.component.css',
})
export class MemberPrimaryLayoutComponent {}
