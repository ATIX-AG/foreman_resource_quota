import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import {
  FormGroup,
  FormHelperText,
  HelperText,
  HelperTextItem,
  TextInput,
  InputGroup,
  InputGroupItem,
  InputGroupText,
} from '@patternfly/react-core';
import { ExclamationCircleIcon } from '@patternfly/react-icons';

import {
  Dropdown,
  DropdownItem,
  DropdownToggle,
} from '@patternfly/react-core/deprecated';

import { sprintf, translate as __ } from 'foremanReact/common/I18n';

import './UnitInputField.scss';
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
        ouiaId={`unit-dropdownitem-${unit.symbol.toLowerCase()}`}
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
      <InputGroupItem>
        <Dropdown
          ouiaId="resource-quota-unit-input-field-input-group-item-dropdown"
          onSelect={onUnitSelect}
          toggle={
            <DropdownToggle
              isDisabled={isDisabled}
              ouiaId="resource-quota-unit-input-field-input-group-item-dropdowni-toggle"
              onToggle={(_event, _val) => onUnitToggle()}
            >
              {__(`${selectedUnit.symbol}`)}
            </DropdownToggle>
          }
          isOpen={isUnitOpen}
          dropdownItems={unitDropdownItems}
        />
      </InputGroupItem>
    );
  };

  const renderFormHelperText = () => {
    if (validated === 'error') {
      return (
        <FormHelperText>
          <HelperText>
            <HelperTextItem
              icon={<ExclamationCircleIcon />}
              variant={validated}
            >
              {errorText}
            </HelperTextItem>
          </HelperText>
        </FormHelperText>
      );
    }
    if (validated === 'warning') {
      return (
        <FormHelperText>
          <HelperText>
            <HelperTextItem
              icon={<ExclamationCircleIcon />}
              variant={validated}
            >
              {errorText}
            </HelperTextItem>
          </HelperText>
        </FormHelperText>
      );
    }
    return <></>;
  };

  return (
    <div className="container-unit-input-field">
      <FormGroup
        label={__('Quota Limit')}
        validated={validated}
        fieldId="quota-limit-resource-quota-form-group"
        labelIcon={labelIcon || {}}
      >
        <InputGroup>
          <InputGroupItem>
            <TextInput
              isDisabled={isDisabled}
              value={inputValue}
              min={minValue}
              max={maxValue}
              validated={validated}
              id="resource-quota-reg-token-life-time-input"
              ouiaId="resource-quota-reg-token-life-time-input"
              onChange={(_event, val) => setInputValue(val)}
            />
          </InputGroupItem>
          {unitView()}
        </InputGroup>
        {renderFormHelperText()}
      </FormGroup>
    </div>
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
