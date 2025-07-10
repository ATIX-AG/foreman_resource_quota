import React, { useState } from 'react';
import { Button, Modal, ModalVariant } from '@patternfly/react-core';

import { translate as __ } from 'foremanReact/common/I18n';
import { getDocsURL } from 'foremanReact/common/helpers';
import EmptyStatePattern from 'foremanReact/components/common/EmptyState/EmptyStatePattern';

import ResourceQuotaForm from '../ResourceQuotaForm';
import { MODAL_ID_CREATE_RESOURCE_QUOTA } from '../ResourceQuotaForm/ResourceQuotaFormConstants';

const ResourceQuotaEmptyState = () => {
  const [isOpen, setIsOpen] = useState(false);

  const onSubmitSuccessCallback = success => {
    if (success) {
      setIsOpen(false);
      window.location.reload();
    }
  };

  const ActionButton = (
    <Button
      id="foreman-resource-quota-welcome-create-modal-button"
      ouiaId="foreman-resource-quota-welcome-create-modal-button"
      variant="primary"
      onClick={() => {
        setIsOpen(true);
      }}
    >
      {__('Create resource quota')}
    </Button>
  );

  const description = (
    <span>
      {__(
        'Resource Quotas help admins to manage resources including CPUs, memory, and disk space among users or user groups.'
      )}
      <br />
      {__(
        'Define a Resource Quota here and apply it to users to guarantee a fair share of your resources.'
      )}
      <br />
    </span>
  );
  const documentation = {
    url: getDocsURL('Administering_Project', 'limiting-host-resources'),
  };

  return (
    <div>
      <EmptyStatePattern
        icon="pficon pficon-cluster"
        iconType="pf"
        header={__('Resource Quotas')}
        description={description}
        action={ActionButton}
        documentation={documentation}
      />
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

export default ResourceQuotaEmptyState;
