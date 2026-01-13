<?php
/**
 * Twenty Twenty-Five Child Theme Functions
 */

// 사이드바에 표시할 부모 카테고리들 (순서대로)
$sidebar_parent_categories = array(11, 19, 17);

/**
 * 동적으로 사이드바 콘텐츠 생성
 */
function twentytwentyfive_child_render_dynamic_sidebar() {
    global $sidebar_parent_categories;
    
    $html = '';
    $html .= '<!-- wp:group {"layout":{"type":"flex","orientation":"vertical"},"style":{"spacing":{"padding":{"top":"var:preset|spacing|30","bottom":"var:preset|spacing|30","left":"var:preset|spacing|20","right":"var:preset|spacing|20"}},"border":{"radius":"12px"}},"backgroundColor":"tertiary"} -->' . PHP_EOL;
    $html .= '<div class="wp-block-group sidebar-left" style="border-radius:12px">' . PHP_EOL;
    $html .= '	<!-- wp:heading {"level":3,"className":"sidebar-heading"} -->' . PHP_EOL;
    $html .= '	<h3>주제</h3>' . PHP_EOL;
    $html .= '	<!-- /wp:heading -->' . PHP_EOL;
    $html .= '	<!-- wp:list -->' . PHP_EOL;
    $html .= '	<ul>' . PHP_EOL;
    
    // 각 부모 카테고리 처리
    foreach ($sidebar_parent_categories as $parent_id) {
        $parent_cat = get_category($parent_id);
        if (!$parent_cat) {
            continue;
        }
        
        // 자식 카테고리 확인
        $children = get_categories(array(
            'child_of' => $parent_id,
            'hide_empty' => false,
        ));
        
        $parent_url = get_category_link($parent_id);
        $parent_name = esc_html($parent_cat->name);
        
        if (!empty($children)) {
            // 자식이 있으면: 부모 + 자식 구조
            $html .= '		<li>' . PHP_EOL;
            $html .= '			<a href="' . esc_url($parent_url) . '">' . $parent_name . '</a>' . PHP_EOL;
            $html .= '			<ul>' . PHP_EOL;
            
            foreach ($children as $child) {
                $child_url = get_category_link($child->term_id);
                $child_name = esc_html($child->name);
                $html .= '				<li><a href="' . esc_url($child_url) . '">' . $child_name . '</a></li>' . PHP_EOL;
            }
            
            $html .= '			</ul>' . PHP_EOL;
            $html .= '		</li>' . PHP_EOL;
        } else {
            // 자식이 없으면: 부모만
            $html .= '		<li><a href="' . esc_url($parent_url) . '">' . $parent_name . '</a></li>' . PHP_EOL;
        }
    }
    
    $html .= '	</ul>' . PHP_EOL;
    $html .= '	<!-- /wp:list -->' . PHP_EOL;
    $html .= '</div>' . PHP_EOL;
    $html .= '<!-- /wp:group -->' . PHP_EOL;
    
    return $html;
}

/**
 * sidebar-left 템플릿 파트 렌더링 시 동적 콘텐츠 생성
 */
add_filter('render_block', function($block_content, $block) {
    // template-part 블록이고 slug가 sidebar-left인 경우만 처리
    if ($block['blockName'] === 'core/template-part' && 
        isset($block['attrs']['slug']) && 
        $block['attrs']['slug'] === 'sidebar-left') {
        
        return twentytwentyfive_child_render_dynamic_sidebar();
    }
    
    return $block_content;
}, 10, 2);
