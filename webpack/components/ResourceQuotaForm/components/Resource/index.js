import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import {
  Button,
  Card,
  CardExpandableContent,
  CardHeader,
  CardTitle,
  CardBody,
  Switch,
  Flex,
  FlexItem,
  Grid,
  GridItem,
  FormGroup,
} from '@patternfly/react-core';

import LabelIcon from 'foremanReact/components/common/LabelIcon';
import { translate as __ } from 'foremanReact/common/I18n';

import './Resource.scss';
import UnitInputField from './UnitInputField';
import UtilizationProgress from './UtilizationProgress';

import { resourceAttributesByIdentifier } from '../../ResourceQuotaFormConstants';
import { dispatchAPICallbackToast } from '../../../../api_helper';

// TODO: Visualize maximum resource (tooltip?)
// TODO: Add error message if given quota limit exceeds present quota utilization (consumed resources)

const Resource = ({
  resourceIdentifier,
  resourceUtilization,
  initialValue,
  isNewQuota,
  handleInputValidation,
  onChange,
  onApply,
}) => {
  const dispatch = useDispatch();
  const cardId = resourceIdentifier;
  const resourceAttributes = resourceAttributesByIdentifier(resourceIdentifier);
  const resourceTitle = resourceAttributes.name;
  const resourceMinValue = resourceAttributes.minValue;
  const resourceMaxValue = resourceAttributes.maxValue;
  const resourceUnits = resourceAttributes.unit;
  const [constInitialValue, setConstInitialValue] = useState(initialValue);
  const [isExpanded, setIsExpanded] = useState(false);
  const [isInputValid, setIsInputValid] = useState(true);
  const [isEnabled, setIsEnabled] = useState(initialValue !== null);
  const [inputValue, setInputValue] = useState(
    initialValue !== null ? initialValue : 0
  );
  const [isApplyLoading, setIsApplyLoading] = useState(false);
  const [isUpdateApplicable, setIsUpdateApplicable] = useState(false);

  /* in case of editing an existing quota: onApply action */
  const onClickApply = () => {
    if (isEnabled) onApply(applyCallback, { [resourceIdentifier]: inputValue });
    else onApply(applyCallback, { [resourceIdentifier]: null });

    setIsApplyLoading(true);
  };
  const applyCallback = (success, response) => {
    setIsApplyLoading(false);
    if (response.data.hasOwnProperty(resourceIdentifier)) {
      setConstInitialValue(response.data[resourceIdentifier]);
      setInputValue(response.data[resourceIdentifier]);
      setIsEnabled(response.data[resourceIdentifier] !== null);
    }
    dispatch(
      dispatchAPICallbackToast(
        success,
        response,
        `Successfully applied ${resourceTitle}.`,
        `An error occurred appyling ${resourceTitle}.`
      )
    );
  };

  /* apply user input changes to state variables */
  const onChangeEnabled = value => {
    setIsEnabled(value);
  };
  const onExpand = () => {
    setIsExpanded(!isExpanded);
  };
  const onInputChange = value => {
    setInputValue(value);
  };
  const handleInputValidationForInputField = isValid => {
    if (isInputValid !== isValid) {
      setIsInputValid(isValid);
      handleInputValidation({ [resourceIdentifier]: isValid });
    }
  };

  /* operations for changes on enabled, valid or inputValue */
  useEffect(() => {
    if (isEnabled) {
      // card enabled
      if (isInputValid) {
        onChange({ [resourceIdentifier]: inputValue });
        if (inputValue !== constInitialValue) {
          setIsUpdateApplicable(true);
        } else {
          // same value as initial
          setIsUpdateApplicable(false);
        }
      } else {
        // no valid input
        setIsUpdateApplicable(false);
      }
    } else {
      // card disabled
      onChange({ [resourceIdentifier]: null });
      if (constInitialValue !== null) {
        setIsUpdateApplicable(true);
      } else {
        // card has been disabled initially
        setIsUpdateApplicable(false);
      }
    }
  }, [
    isEnabled,
    isInputValid,
    inputValue,
    constInitialValue,
    resourceIdentifier,
    onChange,
  ]);

  const renderApplyButton = () => {
    if (isNewQuota) {
      return <></>;
    }
    return (
      <Button
        isDisabled={!isUpdateApplicable}
        size="sm"
        isActive={isApplyLoading}
        variant="primary"
        onClick={onClickApply}
        isLoading={isApplyLoading}
      >
        {__('Apply')}
      </Button>
    );
  };

  return (
    <Card
      isExpanded={isExpanded}
      isDisabledRaised={!isEnabled}
      id={`resource-card-${cardId}`}
    >
      <CardHeader
        actions={{ actions: renderApplyButton() }}
        onExpand={onExpand}
        isToggleRightAligned={false}
      >
        <Flex>
          <FlexItem>
            <Switch
              id={`switch-${cardId}`}
              aria-label={`switch-${cardId}`}
              onChange={(_event, val) => onChangeEnabled(val)}
              isChecked={isEnabled}
            />
          </FlexItem>
          <FlexItem>
            <CardTitle>{resourceTitle}</CardTitle>
          </FlexItem>
        </Flex>
      </CardHeader>
      <CardExpandableContent>
        <CardBody>
          <Grid hasGutter>
            <GridItem span={6}>
              <UnitInputField
                initialValue={inputValue}
                onChange={onInputChange}
                isDisabled={!isEnabled}
                handleInputValidation={handleInputValidationForInputField}
                minValue={resourceMinValue}
                maxValue={resourceMaxValue}
                units={resourceUnits}
                labelIcon={
                  <LabelIcon
                    text={__(
                      `The total amount of ${resourceTitle} for this quota.`
                    )}
                  />
                }
              />
            </GridItem>
            <GridItem span={6}>
              <FormGroup
                label={__('Consumed resources')}
                fieldId="card-resource-quota-progress-form-group"
                labelIcon={
                  <LabelIcon
                    text={__(
                      `Total ${resourceTitle} currently in use by all hosts assigned to this quota.`
                    )}
                  />
                }
              />
              <UtilizationProgress
                cardId={cardId}
                isNewQuota={isNewQuota}
                resourceUnits={resourceUnits}
                resourceValue={initialValue}
                resourceUtilization={resourceUtilization}
                isEnabled={isEnabled}
              />
            </GridItem>
          </Grid>
        </CardBody>
      </CardExpandableContent>
    </Card>
  );
};

Resource.propTypes = {
  isNewQuota: PropTypes.bool.isRequired,
  resourceIdentifier: PropTypes.string.isRequired,
  initialValue: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.oneOf([null]),
  ]),
  resourceUtilization: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.oneOf([null]),
  ]),
  handleInputValidation: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  onApply: PropTypes.func.isRequired,
};

Resource.defaultProps = {
  resourceUtilization: null,
  initialValue: null,
};

export default Resource;
