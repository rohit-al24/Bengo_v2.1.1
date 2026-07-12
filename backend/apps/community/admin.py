from django.contrib import admin
from .models import FriendRequest, Friendship, VocabHint


@admin.register(FriendRequest)
class FriendRequestAdmin(admin.ModelAdmin):
    list_display   = ['from_user', 'to_user', 'status', 'created_at']
    list_filter    = ['status']
    search_fields  = ['from_user__email', 'from_user__username',
                      'to_user__email',   'to_user__username']
    ordering       = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']

    actions = ['accept_selected', 'reject_selected']

    @admin.action(description='Accept selected requests')
    def accept_selected(self, request, queryset):
        for freq in queryset.filter(status='pending'):
            freq.status = 'accepted'
            freq.save()
            u1, u2 = sorted([freq.from_user, freq.to_user], key=lambda u: u.pk)
            Friendship.objects.get_or_create(user1=u1, user2=u2)
        self.message_user(request, 'Selected requests accepted.')

    @admin.action(description='Reject selected requests')
    def reject_selected(self, request, queryset):
        queryset.filter(status='pending').update(status='rejected')
        self.message_user(request, 'Selected requests rejected.')


@admin.register(Friendship)
class FriendshipAdmin(admin.ModelAdmin):
    list_display   = ['user1', 'user2', 'created_at']
    search_fields  = ['user1__email', 'user1__username',
                      'user2__email', 'user2__username']
    ordering       = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(VocabHint)
class VocabHintAdmin(admin.ModelAdmin):
    list_display   = ['user', 'study_item_id', 'hint_text', 'likes', 'created_at']
    list_filter    = ['study_item_id']
    search_fields  = ['user__email', 'user__username', 'hint_text']
    ordering       = ['-likes', '-created_at']
    readonly_fields = ['created_at', 'likes']
