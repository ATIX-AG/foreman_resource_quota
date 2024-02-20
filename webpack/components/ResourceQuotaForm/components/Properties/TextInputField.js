import React, { useState, useEffect, useCallback } from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';

import { translate as __ } from 'foremanReact/common/I18n';

import ActionableDetail from '../../../../lib/ActionableDetail';
import StaticDetail from './StaticDetail';
import dispatchAPICallbackToast from '../../../../api_helper';

const TextInputField = ({
  initialValue,
  label,
  attribute,
  onChange,
  onApply,
  handleInputValidation,
  isRestrictInputValidation,
  isRequired,
  isTextArea,
  isNewQuota,
}) => {
  const dispatch = useDispatch();
  const [currentAttribute, setCurrentAttribute] = useState();
  const [isLoading, setIsLoading] = useState(false);
  const [isInputValid, setIsInputValid] = useState(!isRequired);
  const [validated, setValidated] = useState(isRequired ? 'error' : 'default');
  const [value, setValue] = useState(initialValue || '');
  const staticKey = `properties-resource-quota-${attribute}-static`;
  const actionKey = `properties-resource-quota-${attribute}-actionable`;

  const isValid = checkValue => {
    if (isRequired && checkValue === '') return false;
    return true;
  };

  const callback = (success, response) => {
    setIsLoading(false);
    dispatchAPICallbackToast(
      dispatch,
      success,
      response,
      `Sucessfully applied ${label}.`,
      `An error occurred appyling ${label}.`
    );
  };

  /* Guard setting of isInputValid to prevent re-render reace condition */
  const localHandleInputValidation = useCallback(
    (valid, firstCall = false) => {
      if (firstCall) {
        setIsInputValid(isInputValid);
        handleInputValidation({ [attribute]: isInputValid });
      } else if (valid !== isInputValid || firstCall) {
        setIsInputValid(valid);
        handleInputValidation({ [attribute]: valid });
      }
    },
    [attribute, handleInputValidation, isInputValid]
  );

  useEffect(() => {
    localHandleInputValidation(false, true); // this will be executed only on the first render (valid is ignored)
  }, [localHandleInputValidation]);

  const onEdit = val => {
    if (val === value) return;
    setValue(val);
    if (isValid(val)) {
      localHandleInputValidation(true);
      setValidated('default');
      if (isNewQuota) {
        onChange({ [attribute]: val });
      } else {
        onApply(callback, { [attribute]: val });
        setIsLoading(true);
      }
    } else {
      localHandleInputValidation(false);
      setValidated('error');
    }
  };

  return isNewQuota ? (
    <StaticDetail
      id={staticKey}
      value={value}
      label={label}
      onChange={onEdit}
      isRequired={isRequired}
      validated={validated}
      isTextArea={isTextArea}
    />
  ) : (
    <ActionableDetail
      key={actionKey}
      label={isRequired ? __(`${label} *`) : __(`${label}`)}
      attribute={attribute}
      loading={isLoading && currentAttribute === attribute}
      onEdit={onEdit}
      value={value}
      disabled={false}
      textArea={isTextArea}
      validated={validated}
      {...{ currentAttribute, setCurrentAttribute }}
    />
  );
};

TextInputField.defaultProps = {
  initialValue: '',
  isTextArea: false,
  isRequired: false,
  isRestrictInputValidation: false,
  isNewQuota: false,
};

TextInputField.propTypes = {
  initialValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  attribute: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onApply: PropTypes.func.isRequired,
  handleInputValidation: PropTypes.func.isRequired,
  isRestrictInputValidation: PropTypes.bool,
  isTextArea: PropTypes.bool,
  isRequired: PropTypes.bool,
  isNewQuota: PropTypes.bool,
};

export default TextInputField;
