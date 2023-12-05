import componentRegistry from 'foremanReact/components/componentRegistry';
import ResourceQuotaEmptyState from './components/ResourceQuotaEmptyState';
import ResourceQuotaForm from './components/ResourceQuotaForm';
import CreateResourceQuotaModal from './components/CreateResourceQuotaModal';
import UpdateResourceQuotaModal from './components/UpdateResourceQuotaModal';

/* register React components for erb mounting */
componentRegistry.register({
  name: 'ResourceQuotaEmptyState',
  type: ResourceQuotaEmptyState,
});
componentRegistry.register({
  name: 'ResourceQuotaForm',
  type: ResourceQuotaForm,
});
componentRegistry.register({
  name: 'UpdateResourceQuotaModal',
  type: UpdateResourceQuotaModal,
});
componentRegistry.register({
  name: 'CreateResourceQuotaModal',
  type: CreateResourceQuotaModal,
});
