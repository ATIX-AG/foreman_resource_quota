import React from 'react';
import '@testing-library/jest-dom';

import { render, screen, fireEvent, within } from '@testing-library/react';

import { withMockedProvider, withRedux } from '../../../test_helper';
import ResourceQuotaEmptyState from '../index';

const TestComponent = withRedux(withMockedProvider(ResourceQuotaEmptyState));

describe('ResourceQuotaEmptyState', () => {
  test('renders the create button without an open modal', () => {
    render(<TestComponent />);

    expect(
      screen.getByRole('button', { name: 'Create resource quota' })
    ).toBeInTheDocument();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  test('opens the modal on clicking "Create resource quota" button', () => {
    render(<TestComponent />);

    fireEvent.click(
      screen.getByRole('button', { name: 'Create resource quota' })
    );

    const dialog = screen.getByRole('dialog');
    expect(dialog).toBeInTheDocument();
    expect(within(dialog).getByText('Properties')).toBeInTheDocument();
    expect(within(dialog).getByText('Name *')).toBeInTheDocument();
    expect(within(dialog).getByText('Description')).toBeInTheDocument();
  });
});
