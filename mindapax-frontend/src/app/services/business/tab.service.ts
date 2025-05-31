import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class TabService {
  /**
   * Initialize tabs functionality
   * @param tabsElementId The ID of the container element that holds all tabs
   */
  initializeTabs(tabsElementId: string): void {
    setTimeout(() => {
      const tabsContainer = document.getElementById(tabsElementId);
      if (!tabsContainer) return;

      const tabs = tabsContainer.querySelectorAll('[role="tab"]');
      const tabContents = tabsContainer.querySelectorAll('[role="tabpanel"]');

      tabs.forEach((tab) => {
        tab.addEventListener('click', () => {
          // Deactivate all tabs
          tabs.forEach((t) => {
            t.classList.remove('border-blue-600', 'active');
            t.classList.add('border-transparent');
            t.setAttribute('aria-selected', 'false');
          });

          // Hide all tab contents
          tabContents.forEach((content) => {
            content.classList.add('hidden');
          });

          // Activate clicked tab
          tab.classList.remove('border-transparent');
          tab.classList.add('border-blue-600', 'active');
          tab.setAttribute('aria-selected', 'true');

          // Show corresponding content
          const tabContentId = tab.getAttribute('aria-controls');
          if (tabContentId) {
            const content = document.getElementById(tabContentId);
            if (content) {
              content.classList.remove('hidden');
            }
          }
        });
      });
    }, 0);
  }
}
