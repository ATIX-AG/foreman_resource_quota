import { dispatchAPICallbackToast } from './api_helper';

jest.mock('foremanReact/components/ToastsList', () => ({
  addToast: jest.fn(param => param),
}));

jest.mock('foremanReact/common/I18n', () => ({
  translate: jest.fn(param => param),
}));

const dispatch = jest.fn();

describe('dispatchAPICallbackToast', () => {
  afterEach(() => {
    jest.clearAllMocks(); // Reset mock calls after each test
  });

  it('should dispatch a success toast', () => {
    const isSuccess = true;
    const response = {};
    const successMessage = 'Success message';
    const errorMessage = 'Error message';

    const dispatcher = dispatchAPICallbackToast(
      isSuccess,
      response,
      successMessage,
      errorMessage
    );
    dispatcher(dispatch);

    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenCalledWith({
      type: 'success',
      message: 'Success message',
    });
  });

  it('should dispatch a warning toast with error', () => {
    const isSuccess = false;
    const response = {
      response: {
        data: {
          error: {
            full_messages: 'Some nice error',
          },
        },
      },
    };
    const successMessage = 'Success message';
    const errorMessage = 'Error message';

    const dispatcher = dispatchAPICallbackToast(
      isSuccess,
      response,
      successMessage,
      errorMessage
    );
    dispatcher(dispatch);

    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenCalledWith({
      type: 'warning',
      message: 'Error message Some nice error',
    });
  });

  it('should dispatch a warning toast without error', () => {
    const isSuccess = false;
    const response = {
      response: {
        data: {
          notTheExpectedErrorFormat: {
            full_messages: 'Some nice error',
          },
        },
      },
    };
    const successMessage = 'Success message';
    const errorMessage = 'Error message';

    const dispatcher = dispatchAPICallbackToast(
      isSuccess,
      response,
      successMessage,
      errorMessage
    );
    dispatcher(dispatch);

    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenCalledWith({
      type: 'warning',
      message: 'Error message',
    });
  });
});
