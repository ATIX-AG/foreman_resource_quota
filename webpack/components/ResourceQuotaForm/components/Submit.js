import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { Button, Flex, FlexItem } from '@patternfly/react-core';

import { translate as __ } from 'foremanReact/common/I18n';
import { addToast } from 'foremanReact/components/ToastsList';

import {
  RESOURCE_IDENTIFIER_ID,
  RESOURCE_IDENTIFIER_NAME,
  RESOURCE_IDENTIFIER_DESCRIPTION,
  RESOURCE_IDENTIFIER_CPU,
  RESOURCE_IDENTIFIER_MEMORY,
  RESOURCE_IDENTIFIER_DISK,
} from '../ResourceQuotaFormConstants';

const Submit = ({ isValid, onCreate, onSubmit }) => {
  const dispatch = useDispatch();
  const [isSubmitLoading, setIsSubmitLoading] = useState(false);

  const handleOnSubmit = () => {
    setIsSubmitLoading(true);
    onCreate(onCreateCallback);
  };

  const onCreateCallback = (success, response) => {
    setIsSubmitLoading(false);
    if (success) {
      dispatch(
        addToast({
          type: 'success',
          message: __(`Sucessfully created new Resource Quota`),
        })
      );
    } else {
      dispatch(
        addToast({
          type: 'danger',
          message: __(
            `An error occurred while creating new Resource Quota: ${response.response.data.error.full_messages}`
          ),
        })
      );
    }
    if (onSubmit) onSubmit(success);
  };

  const isAnyInvalid = () => Object.values(isValid).some(value => !value);

  return (
    <Flex>
      <FlexItem align={{ default: 'alignLeft' }}>
        <Button
          isDisabled={isAnyInvalid()}
          onClick={handleOnSubmit}
          isLoading={isSubmitLoading}
          variant="primary"
          id="submit-button"
        >
          {__('Create resource quota')}
        </Button>
      </FlexItem>
    </Flex>
  );
};

Submit.propTypes = {
  isValid: PropTypes.shape({
    [RESOURCE_IDENTIFIER_NAME]: PropTypes.bool,
    [RESOURCE_IDENTIFIER_ID]: PropTypes.bool,
    [RESOURCE_IDENTIFIER_DESCRIPTION]: PropTypes.bool,
    [RESOURCE_IDENTIFIER_CPU]: PropTypes.bool,
    [RESOURCE_IDENTIFIER_MEMORY]: PropTypes.bool,
    [RESOURCE_IDENTIFIER_DISK]: PropTypes.bool,
  }).isRequired,
  onCreate: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
};

export default Submit;
