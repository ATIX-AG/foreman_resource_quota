import React from 'react';
import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';

import LabelIcon from 'foremanReact/components/common/LabelIcon';

import UnitInputField from '../UnitInputField';

const getDefaultProps = () => ({
  initialValue: 0,
  onChange: jest.fn(),
  isDisabled: false,
  handleInputValidation: jest.fn(),
  units: [
    { symbol: 'MiB', factor: 1 },
    { symbol: 'GiB', factor: 1024 },
  ],
  labelIcon: <LabelIcon text="Descriptive title." />,
  minValue: 0,
  maxValue: 5,
});

describe('UnitInputField', () => {
  it('renders the input with the initial value and unit dropdown', () => {
    render(<UnitInputField {...getDefaultProps()} />);
    expect(screen.getByRole('textbox')).toHaveValue('0');
    expect(screen.getByRole('textbox')).toBeEnabled();
    expect(screen.getByText('MiB')).toBeInTheDocument();
  });

  it('renders without dropdown for a single unit', () => {
    render(
      <UnitInputField
        {...getDefaultProps()}
        units={[{ symbol: 'cores', factor: 1 }]}
      />
    );
    expect(screen.getByText('cores')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /cores/i })).toBeNull();
  });

  it('renders as disabled field', () => {
    render(<UnitInputField {...getDefaultProps()} isDisabled />);
    expect(screen.getByRole('textbox')).toBeDisabled();
  });

  it('triggers handleInputValidation on unit change', async () => {
    const props = getDefaultProps();

    render(<UnitInputField {...props} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 3 } });

    // gets called (1.) with initialValue and (2.) the simulated change
    expect(props.onChange).toHaveBeenCalledTimes(2);
    expect(props.onChange).toHaveBeenCalledWith(props.initialValue);
    expect(props.onChange).toHaveBeenLastCalledWith(3);
    expect(props.handleInputValidation).toHaveBeenCalledTimes(2);
    expect(props.handleInputValidation).toHaveBeenCalledWith(true);
  });

  test('triggers onChange with rounded value', () => {
    const props = getDefaultProps();

    render(<UnitInputField {...props} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 3.5 } });

    // gets called (1.) with initialValue and (2.) the simulated change
    expect(props.onChange).toHaveBeenCalledTimes(2);
    expect(props.onChange).toHaveBeenCalledWith(props.initialValue);
    expect(props.onChange).toHaveBeenLastCalledWith(3);
    expect(props.handleInputValidation).toHaveBeenCalledTimes(2);
    expect(props.handleInputValidation).toHaveBeenCalledWith(true);
  });

  test('does not trigger onChange when value out of bounds', () => {
    const props = getDefaultProps();

    render(<UnitInputField {...props} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: props.maxValue + 1 } });

    // onChange only called for initialValue
    expect(props.onChange).toHaveBeenCalledTimes(1);
    expect(props.onChange).toHaveBeenCalledWith(props.initialValue);
    // handleInputValidation called with false => invalid
    expect(props.handleInputValidation).toHaveBeenCalledTimes(2);
    expect(props.handleInputValidation).toHaveBeenLastCalledWith(false);
  });

  test('does not trigger onChange when value is not a number', () => {
    const props = getDefaultProps();

    render(<UnitInputField {...props} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'no number' } });

    // onChange only called for initialValue
    expect(props.onChange).toHaveBeenCalledTimes(1);
    expect(props.onChange).toHaveBeenCalledWith(props.initialValue);
    // handleInputValidation called with false => invalid
    expect(props.handleInputValidation).toHaveBeenCalledTimes(2);
    expect(props.handleInputValidation).toHaveBeenLastCalledWith(false);
  });
});
