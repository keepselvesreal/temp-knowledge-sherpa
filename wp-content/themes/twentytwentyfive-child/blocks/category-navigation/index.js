(function (blocks, element, blockEditor, components, data) {
	var el = element.createElement;
	var useBlockProps = blockEditor.useBlockProps;
	var useSelect = data.useSelect;

	blocks.registerBlockType('twentytwentyfive-child/category-navigation', {
		edit: function (props) {
			var attributes = props.attributes;
			var setAttributes = props.setAttributes;
			var blockProps = useBlockProps();

			// WordPress 카테고리 데이터 가져오기
			var categories = useSelect(function (select) {
				return select('core').getEntityRecords('taxonomy', 'category', {
					per_page: -1,
					order: 'asc',
					orderby: 'name'
				});
			});

			if (!categories) {
				return el('p', blockProps, '카테고리를 로드하는 중...');
			}

			// 현재 선택된 카테고리들
			var selectedIds = attributes.parentCategories || [];

			// 순서 변경 함수
			var moveCategory = function (index, direction) {
				var newIds = selectedIds.slice();
				if (direction === 'up' && index > 0) {
					var temp = newIds[index];
					newIds[index] = newIds[index - 1];
					newIds[index - 1] = temp;
				} else if (direction === 'down' && index < newIds.length - 1) {
					var temp = newIds[index];
					newIds[index] = newIds[index + 1];
					newIds[index + 1] = temp;
				}
				setAttributes({ parentCategories: newIds });
			};

			// 카테고리 제거 함수
			var removeCategory = function (index) {
				var newIds = selectedIds.slice();
				newIds.splice(index, 1);
				setAttributes({ parentCategories: newIds });
			};

			// 실제 렌더링될 카테고리 계층 구조 생성
			var renderCategoryTree = function () {
				return el(
					'div',
					{ style: { padding: '20px', backgroundColor: '#f5f5f5', borderRadius: '12px' } },
					el('h3', { style: { margin: '0 0 16px 0', fontSize: '18px', fontWeight: 'bold' } }, '주제'),
					selectedIds.length === 0
						? el('p', { style: { color: '#999', marginTop: '8px' } }, '사이트 편집에서 카테고리를 추가하세요')
						: el(
							'ul',
							{ style: { margin: 0, paddingLeft: '20px', listStyle: 'disc' } },
							selectedIds.map(function (parentId, index) {
								var parentCat = categories.find(function (c) { return c.id === parentId; });
								if (!parentCat) return null;

								// 이 부모의 자식 카테고리 찾기
								var children = categories.filter(function (cat) { return cat.parent === parentId; });

								var itemStyle = {
									padding: '12px',
									margin: '8px 0',
									backgroundColor: '#fff',
									borderRadius: '4px',
									border: '1px solid #ddd',
									display: 'flex',
									justifyContent: 'space-between',
									alignItems: 'flex-start'
								};

								var buttonContainerStyle = {
									display: 'flex',
									gap: '4px',
									flexShrink: 0,
									marginLeft: '12px'
								};

								var buttonStyle = {
									padding: '4px 8px',
									fontSize: '12px',
									cursor: 'pointer',
									backgroundColor: '#f0f0f0',
									border: '1px solid #ccc',
									borderRadius: '3px',
									color: '#333'
								};

								var contentStyle = {
									flex: 1
								};

								if (children.length === 0) {
									// 자식이 없으면 부모만 표시
									return el(
										'li',
										{ key: 'parent-' + parentId, style: { listStyle: 'none', marginLeft: '-20px' } },
										el(
											'div',
											{ style: itemStyle },
											el(
												'div',
												{ style: contentStyle },
												el('a', { href: '#', style: { color: '#0073aa', textDecoration: 'none' } }, parentCat.name)
											),
											el(
												'div',
												{ style: buttonContainerStyle },
												index > 0 ? el('button', {
													onClick: function () { moveCategory(index, 'up'); },
													style: buttonStyle
												}, '▲') : null,
												index < selectedIds.length - 1 ? el('button', {
													onClick: function () { moveCategory(index, 'down'); },
													style: buttonStyle
												}, '▼') : null,
												el('button', {
													onClick: function () { removeCategory(index); },
													style: { ...buttonStyle, color: '#d32f2f' }
												}, '✕')
											)
										)
									);
								} else {
									// 자식이 있으면 부모 + 자식 구조
									return el(
										'li',
										{ key: 'parent-' + parentId, style: { listStyle: 'none', marginLeft: '-20px' } },
										el(
											'div',
											{ style: itemStyle },
											el(
												'div',
												{ style: contentStyle },
												el('a', { href: '#', style: { color: '#0073aa', textDecoration: 'none', fontWeight: 'bold' } }, parentCat.name),
												el(
													'ul',
													{ style: { margin: '8px 0 0 0', paddingLeft: '20px', listStyle: 'circle' } },
													children.map(function (child) {
														return el(
															'li',
															{ key: 'child-' + child.id },
															el('a', { href: '#', style: { color: '#0073aa', textDecoration: 'none' } }, child.name)
														);
													})
												)
											),
											el(
												'div',
												{ style: buttonContainerStyle },
												index > 0 ? el('button', {
													onClick: function () { moveCategory(index, 'up'); },
													style: buttonStyle
												}, '▲') : null,
												index < selectedIds.length - 1 ? el('button', {
													onClick: function () { moveCategory(index, 'down'); },
													style: buttonStyle
												}, '▼') : null,
												el('button', {
													onClick: function () { removeCategory(index); },
													style: { ...buttonStyle, color: '#d32f2f' }
												}, '✕')
											)
										)
									);
								}
							})
						)
				);
			};

			return el(
				'div',
				blockProps,
				renderCategoryTree()
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
	window.wp.components,
	window.wp.data
);
