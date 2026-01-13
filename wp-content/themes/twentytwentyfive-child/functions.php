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

/**
 * 인기 포스트 조회
 */
function twentytwentyfive_child_get_popular_post($category_id = null) {
    $args = array(
        'post_type' => 'post',
        'posts_per_page' => 1,
        'meta_key' => 'post_views_count',
        'orderby' => 'meta_value_num',
        'order' => 'DESC',
        'post_status' => 'publish',
    );

    if ($category_id) {
        $args['cat'] = $category_id;
    }

    $posts = get_posts($args);
    return !empty($posts) ? $posts[0] : null;
}

/**
 * Dynamic Block: Popular Post Render Callback
 */
function twentytwentyfive_child_render_popular_post($attributes) {
    $type = $attributes['type'] ?? 'all';
    $category_id = null;

    // 타입에 따라 카테고리 결정
    if ($type === 'category') {
        global $post;

        // 범주 페이지인 경우
        if (is_category()) {
            $category_id = get_queried_object_id();
        }
        // 개별 포스트 페이지인 경우
        elseif (is_singular('post') && $post) {
            $categories = get_the_category($post->ID);
            if (!empty($categories)) {
                $category_id = $categories[0]->term_id;
            }
        }
    }

    // 인기 포스트 가져오기
    $popular_post = ($type === 'all')
        ? twentytwentyfive_child_get_popular_post()
        : twentytwentyfive_child_get_popular_post($category_id);

    // 포스트가 없으면 메시지 반환
    if (!$popular_post) {
        return '<p style="color: #999; font-size: 0.9em;">인기 포스트가 없습니다.</p>';
    }

    // HTML 생성
    $post_url = get_permalink($popular_post->ID);
    $post_title = esc_html($popular_post->post_title);
    $post_views = get_post_meta($popular_post->ID, 'post_views_count', true) ?: 0;

    $html = '<div class="popular-post-item">';
    $html .= '<a href="' . esc_url($post_url) . '">' . $post_title . '</a>';
    $html .= ' <span style="color: #999; font-size: 0.9em;">(' . intval($post_views) . ' views)</span>';
    $html .= '</div>';

    return $html;
}

/**
 * Register Dynamic Block
 */
function twentytwentyfive_child_register_popular_post_block() {
    wp_register_script(
        'twentytwentyfive-child-popular-post-editor',
        get_stylesheet_directory_uri() . '/blocks/popular-post/index.js',
        array('wp-blocks', 'wp-element', 'wp-block-editor', 'wp-components'),
        filemtime(get_stylesheet_directory() . '/blocks/popular-post/index.js')
    );

    register_block_type(
        get_stylesheet_directory() . '/blocks/popular-post',
        array(
            'editor_script' => 'twentytwentyfive-child-popular-post-editor',
            'render_callback' => 'twentytwentyfive_child_render_popular_post',
        )
    );
}
add_action('init', 'twentytwentyfive_child_register_popular_post_block');

