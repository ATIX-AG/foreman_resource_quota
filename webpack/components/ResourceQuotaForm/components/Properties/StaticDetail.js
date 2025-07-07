import React from 'react';
import PropTypes from 'prop-types';
import {
  TextListItem,
  TextListItemVariants,
  TextInput,
  TextArea,
} from '@patternfly/react-core';

import { translate as __ } from 'foremanReact/common/I18n';

import '../../../../lib/EditableTextInput/editableTextInput.scss';

const StaticDetail = ({
  value,
  label,
  id,
  onChange,
  isTextArea,
  validated,
  isRequired,
}) => {
  const finalLabel = isRequired ? __(`${label} *`) : __(`${label}`);

  return (
    <React.Fragment key={label}>
      <TextListItem component={TextListItemVariants.dt}>
        {finalLabel}
      </TextListItem>
      <TextListItem
        component={TextListItemVariants.dd}
        className="foreman-spaced-list"
      >
        {isTextArea ? (
          <TextArea
            id={id}
            onChange={(_event, val) => onChange(val)}
            value={value}
            validated={validated}
            isRequired={isRequired}
          />
        ) : (
          <TextInput
            id={id}
            ouiaId={id}
            onChange={(_event, val) => onChange(val)}
            value={value}
            validated={validated}
            isRequired={isRequired}
          />
        )}
      </TextListItem>
    </React.Fragment>
  );
};

StaticDetail.defaultProps = {
  value: '',
  isTextArea: false,
  isRequired: false,
};

StaticDetail.propTypes = {
  value: PropTypes.string,
  id: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  validated: PropTypes.string.isRequired,
  isTextArea: PropTypes.bool,
  isRequired: PropTypes.bool,
};

export default StaticDetail;
