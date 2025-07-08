/* eslint-disable promise/prefer-await-to-then */
// Configure Enzyme
import { mount } from 'enzyme';
import React from 'react';
import { Provider } from 'react-redux';
import store from 'foremanReact/redux';
import LabelIcon from 'foremanReact/components/common/LabelIcon';
import StatusPropertiesLabel from './StatusPropertiesLabel';

const defaultProps = {
  color: 'blue',
  iconChild: <LabelIcon text="test" />,
  statusContent: 'some content',
  linkUrl: '/test/link',
  tooltipText: 'Some nice tooltip',
};

describe('StatusPropertiesLabel', () => {
  const wrapper = mount(
    <Provider store={store}>
      <StatusPropertiesLabel {...defaultProps} />
    </Provider>
  );

  it('includes components', () => {
    expect(wrapper.find('Tooltip').exists()).toBe(true);
    expect(wrapper.find('Tooltip')).toHaveLength(1);
    expect(wrapper.find('Label').exists()).toBe(true);
    expect(wrapper.find('Label')).toHaveLength(1);
    expect(wrapper.find('Link').exists()).toBe(true);
    expect(wrapper.find('Link')).toHaveLength(1);
  });

  it('passes properties', () => {
    // ToolTip
    const tooltip = wrapper.find('Tooltip');
    expect(tooltip.props()).toHaveProperty('content');
    expect(tooltip.prop('content')).toContain(defaultProps.tooltipText);
    // Label
    const label = wrapper.find('Label');
    expect(label.props()).toHaveProperty('icon');
    expect(label.prop('icon')).toEqual(defaultProps.iconChild);
    expect(label.props()).toHaveProperty('color');
    expect(label.prop('color')).toEqual(defaultProps.color);
    // Link
    const link = wrapper.find('Link');
    expect(link.props()).toHaveProperty('to');
    expect(link.prop('to')).toEqual(defaultProps.linkUrl);
  });
});
