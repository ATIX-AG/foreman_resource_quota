import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import {
  FormGroup,
  FormHelperText,
  TextInput,
  InputGroup,
  InputGroupText,
  Dropdown,
  DropdownItem,
  DropdownToggle,
} from '@patternfly/react-core';

import { sprintf, translate as __ } from 'foremanReact/common/I18n';

import { findLargestFittingUnit } from '../../../../helper';

const UnitInputField = ({
  initialValue,
  onChange,
  isDisabled,
  handleInputValidation,
  minValue,
  maxValue,
  units,
  labelIcon,
}) => {
  /* flexible unit adaption variables */
  const [errorText, setErrorText] = useState('');
  const [validated, setValidated] = useState('default');
  const [isUnitOpen, setIsUnitOpen] = useState(false);
  const bestFitUnit = findLargestFittingUnit(initialValue, units);
  const [selectedUnit, setSelectedUnit] = useState(bestFitUnit);
  const [inputValue, setInputValue] = useState(
    initialValue / bestFitUnit.factor
  );
  let unitDropdownItems = [];

  /* generate unitDropdownItems depending on unit */
  if (units.length > 1) {
    unitDropdownItems = units.map(unit => (
      <DropdownItem
        id={`unit-dropdownitem-${unit.symbol.toLowerCase()}`}
        key={unit.symbol.toLowerCase()}
      >
        {unit.symbol}
      </DropdownItem>
    ));
  }

  /* text for bounds errors */
  const errorTextBounds = useCallback(() => {
    const boundsText = 'Value must be between %d and %d.';
    let errorMin = minValue;
    let errorMax = maxValue;
    if (selectedUnit) {
      errorMin = minValue / selectedUnit.factor;
      errorMax = maxValue / selectedUnit.factor;
    }
    return __(sprintf(boundsText, errorMin, errorMax));
  }, [minValue, maxValue, selectedUnit]);

  /* text for float errors */
  const errorTextNatural = useCallback(() => __('Value must be a number.'), []);

  /* text for float inputs (rounding) */
  const warningTextRounded = useCallback(
    roundedValue => __(`Rounding to: ${roundedValue} (${units[0].symbol}).`),
    [units]
  );

  /* warning text displayed beneath value input field (built-in is used for errors) */
  const helperTextWarning = (text, isHidden) => (
    <FormHelperText isHidden={isHidden}>{text}</FormHelperText>
  );

  /* applies the selected unit and checks the bounds */
  const isValid = useCallback(
    val => {
      if (Number.isNaN(Number(val))) {
        setErrorText(errorTextNatural());
        return false;
      }
      const baseValue = valueToBaseUnit(val);
      if (baseValue < minValue || baseValue > maxValue) {
        setErrorText(errorTextBounds());
        return false;
      }
      return true;
    },
    [minValue, maxValue, valueToBaseUnit, errorTextNatural, errorTextBounds]
  );

  /* applies the selected unit and returns the base-unit value */
  const valueToBaseUnit = useCallback(
    val => {
      if (units.length > 1) {
        return selectedUnit.factor * val;
      }
      return Number(val);
    },
    [units, selectedUnit]
  );

  useEffect(() => {
    if (isDisabled) {
      handleInputValidation(true);
      setValidated('default');
    } else if (isValid(inputValue)) {
      const baseValue = valueToBaseUnit(inputValue);
      let validatedValue = baseValue;
      if (baseValue !== Math.floor(baseValue)) {
        validatedValue = Math.floor(baseValue);
        setErrorText(warningTextRounded(validatedValue));
        setValidated('warning');
      } else {
        // Keep baseValue as validatedValue
        setValidated('default');
      }
      onChange(validatedValue);
      handleInputValidation(true);
    } else {
      handleInputValidation(false);
      setValidated('error');
    }
  }, [
    isDisabled,
    inputValue,
    selectedUnit,
    handleInputValidation,
    onChange,
    isValid,
    valueToBaseUnit,
    warningTextRounded,
  ]);

  /* set the selected unit */
  const onUnitSelect = event => {
    const { id } = event.currentTarget;
    const selectedListItem = unitDropdownItems.find(
      item => item.props.id === id
    );
    const unitItem = units.find(
      item => item.symbol === selectedListItem.props.children
    );
    setSelectedUnit(unitItem);
    setIsUnitOpen(false);
    // FIXME: Fix input validation on unit selection
  };

  const onUnitToggle = () => {
    setIsUnitOpen(!isUnitOpen);
  };

  /* return the unit view depending on the available units
   *
   * unit = null : don't print any unit
   * unit = [.]  : print a single Textfield
   * unit = [..] : print an editable Dropdown menu
   * */
  const unitView = () => {
    if (units.length === 1) {
      return <InputGroupText>{__(units[0].symbol)}</InputGroupText>;
    }

    return (
      <Dropdown
        onSelect={onUnitSelect}
        toggle={
          <DropdownToggle isDisabled={isDisabled} onToggle={onUnitToggle}>
            {__(`${selectedUnit.symbol}`)}
          </DropdownToggle>
        }
        isOpen={isUnitOpen}
        dropdownItems={unitDropdownItems}
      />
    );
  };

  return (
    <FormGroup
      label={__('Quota Limit')}
      validated={validated}
      helperTextInvalid={errorText}
      helperText={helperTextWarning(errorText, validated !== 'warning')}
      fieldId="quota-limit-resource-quota-form-group"
      labelIcon={labelIcon || {}}
    >
      <InputGroup>
        <TextInput
          isDisabled={isDisabled}
          value={inputValue}
          min={minValue}
          max={maxValue}
          validated={validated}
          id="reg_token_life_time_input"
          onChange={setInputValue}
        />
        {unitView()}
      </InputGroup>
    </FormGroup>
  );
};

UnitInputField.propTypes = {
  initialValue: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  onChange: PropTypes.func.isRequired,
  isDisabled: PropTypes.bool.isRequired,
  handleInputValidation: PropTypes.func.isRequired,
  units: PropTypes.arrayOf(
    PropTypes.shape({
      symbol: PropTypes.string,
      factor: PropTypes.number,
    })
  ).isRequired,
  labelIcon: PropTypes.node,
  minValue: PropTypes.number.isRequired,
  maxValue: PropTypes.number.isRequired,
};

UnitInputField.defaultProps = {
  initialValue: 0,
  labelIcon: null,
};

export default UnitInputField;
