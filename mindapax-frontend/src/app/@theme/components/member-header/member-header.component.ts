import { Component, OnInit } from '@angular/core';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-member-header',
  imports: [],
  templateUrl: './member-header.component.html',
  styleUrl: './member-header.component.css',
})
export class MemberHeaderComponent implements OnInit {
  userName: string = '';

  constructor(private authService: AuthService) {}

  ngOnInit(): void {
    this.userName =
      this.authService.getFirstName() ||
      '' + ' ' + this.authService.getLastName() ||
      '';
  }
}
