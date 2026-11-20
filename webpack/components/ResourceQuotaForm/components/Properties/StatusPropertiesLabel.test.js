import React from 'react';
import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import { Provider } from 'react-redux';
import store from 'foremanReact/redux';
import StatusPropertiesLabel from './StatusPropertiesLabel';

const defaultProps = {
  color: 'blue',
  iconChild: <span data-testid="status-icon" />,
  statusContent: 'some content',
  linkUrl: '/test/link',
  tooltipText: 'Some nice tooltip',
};

describe('StatusPropertiesLabel', () => {
  beforeEach(() => {
    render(
      <Provider store={store}>
        <StatusPropertiesLabel {...defaultProps} />
      </Provider>
    );
  });

  it('renders the status content as a link', () => {
    const link = screen.getByRole('link');
    expect(link).toHaveTextContent(defaultProps.statusContent);
    expect(link).toHaveAttribute('href', defaultProps.linkUrl);
  });

  it('renders a blue label', () => {
    const label = screen.getByRole('link').closest('.pf-v5-c-label');
    expect(label).toHaveClass('pf-m-blue');
  });

  it('renders the icon inside the label', () => {
    expect(
      screen.getByRole('link').closest('.pf-v5-c-label')
    ).toContainElement(screen.getByTestId('status-icon'));
  });

  it('shows the tooltip text on hover', async () => {
    // PF Tooltip listens for mouseenter on the label root, which doesn't bubble
    fireEvent.mouseEnter(screen.getByRole('link').closest('.pf-v5-c-label'));
    expect(
      await screen.findByText(defaultProps.tooltipText)
    ).toBeInTheDocument();
  });
});
