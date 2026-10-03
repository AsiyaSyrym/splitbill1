const tabs = document.querySelectorAll('[data-auth-tab]');
const forms = document.querySelectorAll('[data-auth-form]');

tabs.forEach((tab) => {
	tab.addEventListener('click', () => {
		const selectedForm = tab.dataset.authTab;

		tabs.forEach((item) => {
			const selected = item === tab;
			item.classList.toggle('is-active', selected);
			item.setAttribute('aria-selected', String(selected));
		});

		forms.forEach((form) => {
			form.classList.toggle('is-hidden', form.dataset.authForm !== selectedForm);
		});
	});
});
