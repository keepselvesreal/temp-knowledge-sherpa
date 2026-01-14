(function (blocks, element, blockEditor, components) {
	var el = element.createElement;
	var useBlockProps = blockEditor.useBlockProps;
	var InspectorControls = blockEditor.InspectorControls;
	var PanelBody = components.PanelBody;
	var SelectControl = components.SelectControl;

	blocks.registerBlockType('twentytwentyfive-child/popular-post', {
		edit: function (props) {
			var attributes = props.attributes;
			var setAttributes = props.setAttributes;
			var blockProps = useBlockProps();

			return el(
				'div',
				blockProps,
				el(
					InspectorControls,
					{},
					el(
						PanelBody,
						{ title: '설정' },
						el(SelectControl, {
							label: '타입',
							value: attributes.type,
							options: [
								{ label: '전체 인기 포스트', value: 'all' },
								{ label: '현재 범주 인기 포스트', value: 'category' }
							],
							onChange: function (value) {
								setAttributes({ type: value });
							}
						})
					)
				),
				el(
					'div',
					{ style: { padding: '20px', backgroundColor: '#f0f0f0', borderRadius: '4px' } },
					el('p', { style: { margin: 0, fontWeight: 'bold' } }, '인기 포스트'),
					el(
						'p',
						{ style: { margin: '8px 0 0 0', fontSize: '14px', color: '#666' } },
						attributes.type === 'all' ? '전체 조회수 1등 포스트' : '현재 범주 조회수 1등 포스트'
					)
				)
			);
		},
		save: function () {
			return null;
		}
	});
})(
	window.wp.blocks,
	window.wp.element,
	window.wp.blockEditor,
	window.wp.components
);
