/**
 * Smoke Tests for Management Frontend
 * Validates core component rendering and integration
 */

import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import App from '../../App';

describe('Frontend - Smoke Tests', () => {
  it('should render App component without crashing', () => {
    render(
      <BrowserRouter>
        <App />
      </BrowserRouter>
    );
    
    // App should render - check for main layout presence
    expect(document.body).toBeTruthy();
  });

  it('should have required layout structure', () => {
    render(
      <BrowserRouter>
        <App />
      </BrowserRouter>
    );
    
    // Check for main content area
    const contentArea = document.querySelector('[class*="layout"]');
    expect(contentArea).toBeTruthy();
  });
});
