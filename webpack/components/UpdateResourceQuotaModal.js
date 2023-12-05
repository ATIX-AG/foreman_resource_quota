import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { Modal, ModalVariant } from '@patternfly/react-core';

import { translate as __ } from 'foremanReact/common/I18n';

import ResourceQuotaForm from './ResourceQuotaForm';
import {
  MODAL_ID_UPDATE_RESOURCE_QUOTA,
  RESOURCE_IDENTIFIER_ID,
  RESOURCE_IDENTIFIER_NAME,
  RESOURCE_IDENTIFIER_DESCRIPTION,
  RESOURCE_IDENTIFIER_CPU,
  RESOURCE_IDENTIFIER_MEMORY,
  RESOURCE_IDENTIFIER_DISK,
  RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS,
  RESOURCE_IDENTIFIER_STATUS_NUM_USERS,
  RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS,
  RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS,
  RESOURCE_IDENTIFIER_STATUS_UTILIZATION,
} from './ResourceQuotaForm/ResourceQuotaFormConstants';

const UpdateResourceQuotaModal = ({ initialProperties, initialStatus }) => {
  const staticId = `${MODAL_ID_UPDATE_RESOURCE_QUOTA}-${initialProperties[RESOURCE_IDENTIFIER_ID]}`;
  const [isOpen, setIsOpen] = useState(false);
  const [quotaProperties, setQuotaProperties] = useState(initialProperties);
  const [quotaStatus, setQuotaStatus] = useState(initialStatus);

  const onQuotaChangesCallback = (updatedProperties, updatedStatus) => {
    setQuotaProperties(updatedProperties);
    setQuotaStatus(updatedStatus);
  };

  return (
    <div>
      <a
        onClick={() => {
          setIsOpen(true);
        }}
      >
        {quotaProperties[RESOURCE_IDENTIFIER_NAME]}
      </a>
      <Modal
        ouiaId={staticId}
        title={__(`Edit: ${quotaProperties[RESOURCE_IDENTIFIER_NAME]}`)}
        variant={ModalVariant.small}
        isOpen={isOpen}
        onClose={() => {
          setIsOpen(false);
        }}
        appendTo={document.body}
      >
        <ResourceQuotaForm
          isNewQuota={false}
          initialProperties={quotaProperties}
          initialStatus={quotaStatus}
          quotaChangesCallback={onQuotaChangesCallback}
        />
      </Modal>
    </div>
  );
};

UpdateResourceQuotaModal.defaultProps = {
  initialProperties: {
    [RESOURCE_IDENTIFIER_NAME]: '',
    [RESOURCE_IDENTIFIER_DESCRIPTION]: '',
    [RESOURCE_IDENTIFIER_CPU]: null,
    [RESOURCE_IDENTIFIER_MEMORY]: null,
    [RESOURCE_IDENTIFIER_DISK]: null,
  },
  initialStatus: {
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: null,
    [RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_UTILIZATION]: {
      [RESOURCE_IDENTIFIER_CPU]: null,
      [RESOURCE_IDENTIFIER_MEMORY]: null,
      [RESOURCE_IDENTIFIER_DISK]: null,
    },
  },
};

UpdateResourceQuotaModal.propTypes = {
  initialProperties: PropTypes.shape({
    [RESOURCE_IDENTIFIER_ID]: PropTypes.number.isRequired,
    [RESOURCE_IDENTIFIER_NAME]: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_DESCRIPTION]: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_CPU]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_MEMORY]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_DISK]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
  }),
  initialStatus: PropTypes.shape({
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_UTILIZATION]: PropTypes.shape({
      [RESOURCE_IDENTIFIER_CPU]: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.oneOf([null]),
      ]),
      [RESOURCE_IDENTIFIER_MEMORY]: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.oneOf([null]),
      ]),
      [RESOURCE_IDENTIFIER_DISK]: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.oneOf([null]),
      ]),
    }),
  }),
};

export default UpdateResourceQuotaModal;
