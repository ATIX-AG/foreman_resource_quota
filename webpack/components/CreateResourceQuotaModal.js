import React, { useState } from 'react';
import { Button, Modal, ModalVariant } from '@patternfly/react-core';

import { translate as __ } from 'foremanReact/common/I18n';

import ResourceQuotaForm from './ResourceQuotaForm';
import { MODAL_ID_CREATE_RESOURCE_QUOTA } from './ResourceQuotaForm/ResourceQuotaFormConstants';

const CreateResourceQuotaModal = () => {
  const [isOpen, setIsOpen] = useState(false);

  const onSubmitSuccessCallback = success => {
    if (success) {
      setIsOpen(false);
      window.location.reload();
    }
  };

  return (
    <div>
      <Button
        id="foreman-resource-quota-create-modal-button"
        ouiaId="foreman-resource-quota-create-modal-button"
        variant="primary"
        onClick={() => {
          setIsOpen(true);
        }}
      >
        {__('Create resource quota')}
      </Button>{' '}
      <Modal
        ouiaId={MODAL_ID_CREATE_RESOURCE_QUOTA}
        title={__('Create resource quota')}
        variant={ModalVariant.small}
        isOpen={isOpen}
        onClose={() => {
          setIsOpen(false);
        }}
        appendTo={document.body}
      >
        <ResourceQuotaForm isNewQuota onSubmit={onSubmitSuccessCallback} />
      </Modal>
    </div>
  );
};

export default CreateResourceQuotaModal;
